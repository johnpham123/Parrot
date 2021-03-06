import Dispatch
import Darwin.ncurses

// To allow for a Terminal resize handler.
private var _resizeHandler: (Void) -> Void = {}
private func _redraw(sig: Int32) {
	signal(SIGWINCH, SIG_IGN)
	_resizeHandler()
	signal(SIGWINCH, _redraw)
}

/* TODO: Unify raw + cbreak modes. */

struct Terminal {
	
	// Default terminal values, initialized when begin() is called.
	private static var _cursesActive = false
	private static var _rawMode = false
	private static var _charBreak = true
	private static var _echoOn = false
	private static var _halfDelay = 0
	
	// Cannot be initialized; only class functions.
	private init() {}
	
	//
	// Terminal Session
	//
	
	// Starts the ncurses session.
	// Will automatically enable colors if possible.
	static func begin(colors: Bool = true) {
		initscr() // basically just newterm()
		noraw()
		cbreak()
		noecho()
		halfdelay(0)
		
		_cursesActive = true
		if colors {
			Terminal.startColors()
		}
		
		// Set up a resize handler for events
		_resizeHandler = {
			// 1. Fire an Event
			// 2. Responders will cascade down the chain
			// 3. Redraw what needs to be redrawn
			// TODO: Also do this for key events and stuff
			
			endwin();
			initscr()
			refresh();
			clear();
			Canvas.root.needsRedraw()
		}
		signal(SIGWINCH, _redraw)
		_redraw(sig: Int32(0))
	}
	
	// Pause ncurses session to standard terminal.
	static func pause() {
		if _cursesActive {
			def_prog_mode()
			endwin()
			signal(SIGWINCH, SIG_IGN)
			_cursesActive = false
		}
	}
	
	// Resume ncurses session from standard terminal.
	static func resume() {
		if !_cursesActive {
			reset_prog_mode();
			signal(SIGWINCH, _redraw)
			_redraw(sig: Int32(0))
			_cursesActive = true
		}
	}
	
	// Ends the ncurses session.
	static func end() {
		endwin();
		signal(SIGWINCH, SIG_IGN)
		_cursesActive = false
	}
	
	// Is there an active ncurses session?
	static func active() -> Bool {
		return _cursesActive
	}
	
	// Runs an entire Terminal/ncurses session between a begin() and end().
	static func interactive(handler: (Void) -> Void) {
		self.begin()
		handler()
		self.end()
	}
	
	// Executes a handler with the ncurses session paused.
	static func paused(handler: (Void) -> Void) {
		self.pause()
		handler()
		self.resume()
	}
	
	// Block until a certain key (or any key) is pressed.
	static func wait(key: KeyCode? = nil) {
		if key != nil {
			while(getch() != key!.rawValue) {}
		} else {
			getch() // no particular key
		}
	}
	
	// What is the current terminal size?
	static func size() -> Frame {
		return (p: (x: 0, y: 0), s: (w:Int(COLS), h: Int(LINES)))
	}
	
	// Beep the terminal!
	static func bell() {
		beep()
	}
	
	// Does the terminal support a specific key?
	static func supportsKey(key: Int) -> Bool {
		return has_key(Int32(key)) == OK
	}
	
	//
	// Color Properties
	//
	
	// Does the terminal support color mode?
	static func supportsColors() -> Bool {
		return has_colors()
	}
	
	// Does the terminal support changing the colors?
	static func canChangeColors() -> Bool {
		return can_change_color()
	}
	
	// Start color support if possible.
	// Ideally this will be automatic, done by the window.
	static func startColors() {
		if Terminal.supportsColors() {
			start_color()
			use_default_colors()
		}
	}
	
	//
	// Terminal Properties
	//
	
	static func ignoreSignals() -> Bool {
		return _rawMode
	}
	
	static func ignoreSignals(flag: Bool) {
		_ = flag ? raw() : noraw()
		_rawMode = flag
	}
	
	static func printSignals() -> Bool {
		return _charBreak
	}
	
	static func printSignals(flag: Bool) {
		_ = flag ? cbreak() : nocbreak()
		_charBreak = flag
	}
	
	static func echoMode() -> Bool {
		return _echoOn
	}
	
	static func echoMode(flag: Bool) {
		_ = flag ? echo() : noecho()
		_echoOn = flag
	}
	
	static func entryTimeout() -> Int {
		return _halfDelay
	}
	
	static func entryTimeout(value: Int) {
		halfdelay(Int32(value))
		_halfDelay = value
	}
	
	//
	// Terminal Resize
	//
	
	// Sets a handler that is called whenever the terminal is resized.
	// If call is true, the handler will also be called immediately.
	static func onResize(draw: (Void) -> Void) {
		_resizeHandler = draw
		signal(SIGWINCH, _redraw)
	}
}

// Rudimentary event loop to drive UI refreshing and whatnot.
class EventLoop {
	let attr: DispatchQueueAttributes = [.serial, .qosUserInteractive]
	let queue: DispatchQueue
	let source: DispatchSourceTimer
	
	// name - name of the dispatch queue
	// frequency - how many times per second to update
	// handler - what to do during the update
	init(name: String, frequency: Int, handler: (Void) -> Void) {
		queue = DispatchQueue(label: name, attributes: attr)
		source = DispatchSource.timer(queue: queue)
		
		source.scheduleRepeating(deadline: DispatchTime.now(), // FIXME this was borked...
		                         interval: DispatchTimeInterval.seconds(frequency))
		source.setEventHandler(handler: handler)
		source.resume()
	}
	
	deinit {
		source.cancel()
		// can't delete anything :(
	}
	
	// Use only in case of a heavy operation that could backlog the queue.
	// This temporarily disables the queue execution!
	func execute(handler: (Void) -> Void) {
		source.suspend()
		handler()
		source.resume()
	}
}
