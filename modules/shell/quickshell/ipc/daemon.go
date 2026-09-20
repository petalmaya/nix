package main

// nixtop sway ipc daemon — event-driven sway state for quickshell
// Inspired by caelestia/dank: outsource hot IPC to Go, keep QML cheap.
// Watches sway's IPC socket, writes a compact JSON snapshot that QML can
// FileView without spawning `swaymsg` per frame.
//
// Protocol: sway/i3 IPC — header "i3-ipc" + len u32 LE + type u32 LE + payload
// Subscribe type 2, events have 0x80000000 bit. After each event, we
// query GET_WORKSPACES (1) and GET_OUTPUTS (3) synchronously and emit a
// merged snapshot at $XDG_CACHE_HOME/nixtop-shell/sway.json (or ~/.cache/...).
//
// No external deps — stdlib only.

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

const (
	ipcMagic         = "i3-ipc"
	ipcHeaderLen     = 14 // 6 magic + 4 len + 4 type
	ipcGetWorkspaces = 1
	ipcSubscribe     = 2
	ipcGetOutputs    = 3
)

func xdgCache() string {
	if v := os.Getenv("XDG_CACHE_HOME"); v != "" {
		return v
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".cache")
}

func swaySock() string {
	if v := os.Getenv("SWAYSOCK"); v != "" {
		return v
	}
	// i3 fallback (sway uses same protocol)
	if v := os.Getenv("I3SOCK"); v != "" {
		return v
	}
	return ""
}

func ipcEncode(payload []byte, typ uint32) []byte {
	buf := new(bytes.Buffer)
	buf.WriteString(ipcMagic)
	_ = binary.Write(buf, binary.LittleEndian, uint32(len(payload)))
	_ = binary.Write(buf, binary.LittleEndian, typ)
	buf.Write(payload)
	return buf.Bytes()
}

func ipcRoundTrip(sock string, typ uint32, payload []byte) ([]byte, error) {
	conn, err := net.Dial("unix", sock)
	if err != nil {
		return nil, err
	}
	defer conn.Close()
	if _, err := conn.Write(ipcEncode(payload, typ)); err != nil {
		return nil, err
	}
	header := make([]byte, ipcHeaderLen)
	if _, err := io.ReadFull(conn, header); err != nil {
		return nil, err
	}
	if string(header[:6]) != ipcMagic {
		return nil, fmt.Errorf("bad magic %q", header[:6])
	}
	n := binary.LittleEndian.Uint32(header[6:10])
	body := make([]byte, n)
	if n > 0 {
		if _, err := io.ReadFull(conn, body); err != nil {
			return nil, err
		}
	}
	return body, nil
}

type Workspace struct {
	ID      int    `json:"id"`
	Num     int    `json:"num"`
	Name    string `json:"name"`
	Visible bool   `json:"visible"`
	Focused bool   `json:"focused"`
	Urgent  bool   `json:"urgent"`
	Rect    struct {
		X int `json:"x"`
		Y int `json:"y"`
	} `json:"rect"`
	Output string `json:"output"`
}

type Output struct {
	Name             string `json:"name"`
	Active           bool   `json:"active"`
	CurrentWorkspace string `json:"current_workspace"`
}

type Snapshot struct {
	Timestamp int64             `json:"timestamp"`
	Focused   string            `json:"focusedOutput"`
	Current   int               `json:"currentWorkspace"`
	ByOutput  map[string]int    `json:"currentWorkspaceByOutput"`
	Workspaces map[string]any   `json:"workspaces"`
	RawWS     []Workspace       `json:"_rawWorkspaces"`
	Outputs   []Output          `json:"outputs"`
}

func buildSnapshot(wsBody, outBody []byte) ([]byte, error) {
	var workspaces []Workspace
	if err := json.Unmarshal(wsBody, &workspaces); err != nil {
		return nil, fmt.Errorf("workspaces unmarshal: %w", err)
	}
	var outputs []Output
	// get_outputs is not fatal if it fails (older sway)
	if outBody != nil {
		_ = json.Unmarshal(outBody, &outputs)
	}

	byOutput := map[string]int{}
	workspacesMap := map[string]any{}
	focused := ""
	current := 1

	// find focused workspace globally and per output
	for _, w := range workspaces {
		// sway's focused is global; per-output focused is visible+focused?
		if w.Focused {
			focused = w.Output
			current = w.Num
		}
		if w.Visible {
			// visible implies this output's active workspace
			if _, ok := byOutput[w.Output]; !ok || w.Focused {
				byOutput[w.Output] = w.Num
			}
		}
		// shape like MangoWC.workspaces["<output>-<idx>"]
		key := fmt.Sprintf("%s-%d", w.Output, w.Num)
		workspacesMap[key] = map[string]any{
			"idx":       w.Num,
			"output":    w.Output,
			"name":      w.Name,
			"is_focused": w.Focused,
			"is_active":  w.Visible,
			"is_urgent":  w.Urgent,
			"id":        w.ID,
		}
	}
	// fallback focused from outputs if no workspace focused (shouldn't happen)
	if focused == "" && len(outputs) > 0 {
		for _, o := range outputs {
			if o.Active {
				focused = o.Name
				break
			}
		}
		if focused == "" {
			focused = outputs[0].Name
		}
	}

	snap := Snapshot{
		Timestamp:  time.Now().UnixMilli(),
		Focused:    focused,
		Current:    current,
		ByOutput:   byOutput,
		Workspaces: workspacesMap,
		RawWS:      workspaces,
		Outputs:    outputs,
	}
	return json.Marshal(snap)
}

func writeSnapshot(path string, data []byte) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// ---- mango mode: `mmsg watch all-monitors` -> mango.json ----

// mmsg JSON shapes (subset we read; the full object is passed through raw
// so QML's `monitors` map keeps tags/active_tags/layout_symbol/keymode/...).
type mmsgTag struct {
	Index       int    `json:"index"`
	IsActive    bool   `json:"is_active"`
	IsUrgent    bool   `json:"is_urgent"`
	ClientCount int    `json:"client_count"`
	Layout      string `json:"layout"`
}

type mmsgMonitor struct {
	Name       string          `json:"name"`
	Active     bool            `json:"active"`
	ActiveTags []int           `json:"active_tags"`
	Tags       []mmsgTag       `json:"tags"`
}

type mmsgLine struct {
	Monitors []json.RawMessage `json:"monitors"`
}

type mangoSnapshot struct {
	Timestamp    int64          `json:"timestamp"`
	Focused      string         `json:"focusedOutput"`
	Current      int            `json:"currentWorkspace"`
	ByOutput     map[string]int `json:"currentWorkspaceByOutput"`
	Workspaces   map[string]any `json:"workspaces"`
	Monitors     map[string]any `json:"monitors"`
	MonitorList  []any          `json:"monitorList"`
}

func mmsgPath(flagVal string) string {
	if flagVal != "" && flagVal != "mmsg" {
		return flagVal
	}
	p, err := exec.LookPath("mmsg")
	if err != nil {
		return ""
	}
	return p
}

func buildMangoSnapshot(rawMonitors []json.RawMessage) ([]byte, error) {
	byOutput := map[string]int{}
	workspacesMap := map[string]any{}
	monitorsMap := map[string]any{}
	monitorList := []any{}
	focused := ""
	current := 1

	for _, raw := range rawMonitors {
		var m mmsgMonitor
		if err := json.Unmarshal(raw, &m); err != nil {
			continue
		}
		if m.Name == "" {
			continue
		}
		// pass the full object through so QML keeps every mmsg field
		var full any
		if err := json.Unmarshal(raw, &full); err != nil {
			continue
		}
		monitorsMap[m.Name] = full
		monitorList = append(monitorList, full)

		primary := 0
		if len(m.ActiveTags) > 0 {
			primary = m.ActiveTags[0]
		}
		byOutput[m.Name] = primary

		for _, t := range m.Tags {
			key := fmt.Sprintf("%s-%d", m.Name, t.Index)
			workspacesMap[key] = map[string]any{
				"idx":          t.Index,
				"output":       m.Name,
				"is_focused":   m.Active && t.IsActive,
				"name":         nil,
				"is_active":    t.IsActive,
				"is_urgent":    t.IsUrgent,
				"client_count": t.ClientCount,
				"layout":       t.Layout,
			}
		}

		if m.Active {
			focused = m.Name
			current = primary
		}
	}

	snap := mangoSnapshot{
		Timestamp:   time.Now().UnixMilli(),
		Focused:     focused,
		Current:     current,
		ByOutput:    byOutput,
		Workspaces:  workspacesMap,
		Monitors:    monitorsMap,
		MonitorList: monitorList,
	}
	return json.Marshal(snap)
}

func mangoLoop(mmsg string, outPath string) error {
	cmd := exec.Command(mmsg, "watch", "all-monitors")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("mmsg stdout pipe: %w", err)
	}
	cmd.Stderr = os.Stderr
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("mmsg watch start: %w", err)
	}
	defer func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	}()

	scanner := bufio.NewScanner(stdout)
	scanner.Buffer(make([]byte, 64*1024), 10*1024*1024)
	for scanner.Scan() {
		line := scanner.Bytes()
		if len(bytes.TrimSpace(line)) == 0 {
			continue
		}
		var parsed mmsgLine
		if err := json.Unmarshal(line, &parsed); err != nil {
			continue
		}
		if parsed.Monitors == nil {
			continue
		}
		snap, err := buildMangoSnapshot(parsed.Monitors)
		if err != nil {
			continue
		}
		if err := writeSnapshot(outPath, snap); err != nil {
			log.Printf("writeSnapshot: %v", err)
		}
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("mmsg watch read: %w", err)
	}
	return fmt.Errorf("mmsg watch exited")
}

func subscribeLoop(sock string, outPath string) error {
	// initial snapshot
	ws, err := ipcRoundTrip(sock, ipcGetWorkspaces, nil)
	if err != nil {
		return fmt.Errorf("initial get_workspaces: %w", err)
	}
	outs, _ := ipcRoundTrip(sock, ipcGetOutputs, nil)
	snap, err := buildSnapshot(ws, outs)
	if err != nil {
		return err
	}
	if err := writeSnapshot(outPath, snap); err != nil {
		return err
	}
	log.Printf("initial snapshot: %d bytes", len(snap))

	// subscribe connection (long-lived)
	conn, err := net.Dial("unix", sock)
	if err != nil {
		return err
	}
	defer conn.Close()

	subPayload, _ := json.Marshal([]string{"workspace", "window", "output", "mode", "binding"})
	if _, err := conn.Write(ipcEncode(subPayload, ipcSubscribe)); err != nil {
		return fmt.Errorf("subscribe write: %w", err)
	}
	header := make([]byte, ipcHeaderLen)
	if _, err := io.ReadFull(conn, header); err != nil {
		return fmt.Errorf("subscribe reply header: %w", err)
	}
	n := binary.LittleEndian.Uint32(header[6:10])
	if n > 0 {
		body := make([]byte, n)
		if _, err := io.ReadFull(conn, body); err != nil {
			return err
		}
		var res struct {
			Success bool `json:"success"`
		}
		_ = json.Unmarshal(body, &res)
		if !res.Success {
			return fmt.Errorf("subscribe failed: %s", body)
		}
	}
	log.Printf("subscribed to workspace/window/output")

	// event loop — each message triggers a synchronous get_workspaces
	for {
		if _, err := io.ReadFull(conn, header); err != nil {
			return fmt.Errorf("event header: %w", err)
		}
		if string(header[:6]) != ipcMagic {
			return fmt.Errorf("bad event magic %q", header[:6])
		}
		n := binary.LittleEndian.Uint32(header[6:10])
		typ := binary.LittleEndian.Uint32(header[10:14])
		body := make([]byte, n)
		if n > 0 {
			if _, err := io.ReadFull(conn, body); err != nil {
				return fmt.Errorf("event body: %w", err)
			}
		}
		// type includes 0x80000000 for events; we don't care which
		_ = typ
		_ = body

		// debounce: burst of events (e.g. workspace + window) coalesce within 30ms
		time.Sleep(30 * time.Millisecond)
		// drain any pending events already buffered
		_ = conn.SetReadDeadline(time.Now().Add(30 * time.Millisecond))
		for {
			peek := make([]byte, ipcHeaderLen)
			conn.SetReadDeadline(time.Now().Add(5 * time.Millisecond))
			if _, err := io.ReadFull(conn, peek); err != nil {
				break
			}
			nn := binary.LittleEndian.Uint32(peek[6:10])
			if nn > 0 {
				tmp := make([]byte, nn)
				io.ReadFull(conn, tmp)
			}
			// extend debounce window slightly
			time.Sleep(10 * time.Millisecond)
		}
		conn.SetReadDeadline(time.Time{})

		ws, err := ipcRoundTrip(sock, ipcGetWorkspaces, nil)
		if err != nil {
			log.Printf("get_workspaces after event: %v", err)
			continue
		}
		outs, _ := ipcRoundTrip(sock, ipcGetOutputs, nil)
		snap, err := buildSnapshot(ws, outs)
		if err != nil {
			log.Printf("buildSnapshot: %v", err)
			continue
		}
		if err := writeSnapshot(outPath, snap); err != nil {
			log.Printf("writeSnapshot: %v", err)
		}
	}
}

func main() {
	outFlag := flag.String("out", "", "snapshot output path (default $XDG_CACHE_HOME/nixtop-shell/sway.json, or mango.json in mango mode)")
	sockFlag := flag.String("sock", "", "sway IPC socket (default $SWAYSOCK)")
	mangoFlag := flag.Bool("mango", false, "mango mode: watch `mmsg watch all-monitors` instead of sway IPC")
	mmsgFlag := flag.String("mmsg", "mmsg", "mmsg binary for mango mode")
	flag.Parse()

	// Mango mode: explicit flag, or no sway socket but mmsg exists.
	// Keeps one binary for both compositors (installed as nixtop-sway-ipc
	// and nixtop-mango-ipc); QML launches the right name per compositor.
	if *mangoFlag || ((*sockFlag == "" && swaySock() == "") && mmsgPath(*mmsgFlag) != "") {
		mmsg := mmsgPath(*mmsgFlag)
		if mmsg == "" {
			log.Fatalf("no mmsg binary: install mango or pass --mmsg")
		}
		outPath := *outFlag
		if outPath == "" {
			outPath = filepath.Join(xdgCache(), "nixtop-shell", "mango.json")
		}
		log.Printf("nixtop mango ipc daemon: mmsg=%s out=%s", mmsg, outPath)
		for {
			err := mangoLoop(mmsg, outPath)
			log.Printf("mango watch exited: %v; reconnecting in 1s", err)
			time.Sleep(time.Second)
		}
	}

	sock := *sockFlag
	if sock == "" {
		sock = swaySock()
	}
	if sock == "" {
		log.Fatalf("no sway socket: set SWAYSOCK or --sock (or run with --mango under mangowc)")
	}
	outPath := *outFlag
	if outPath == "" {
		outPath = filepath.Join(xdgCache(), "nixtop-shell", "sway.json")
	}

	log.Printf("nixtop sway ipc daemon: sock=%s out=%s", sock, outPath)

	// poll until sway appears (useful at autostart before compositor is ready)
	for {
		if _, err := os.Stat(sock); err == nil {
			break
		}
		log.Printf("waiting for sway socket %s", sock)
		time.Sleep(500 * time.Millisecond)
	}

	for {
		err := subscribeLoop(sock, outPath)
		log.Printf("subscribe loop exited: %v; reconnecting in 1s", err)
		time.Sleep(time.Second)
		// re-resolve sock in case it moved (sway restart)
		if *sockFlag == "" {
			if ns := swaySock(); ns != "" {
				sock = ns
			}
		}
	}
}
