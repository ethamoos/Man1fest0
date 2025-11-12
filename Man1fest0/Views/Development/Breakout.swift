//
//  Ball.swift
//  Man1fest0
//
//  Created by Amos Deane on 11/11/2025.
//


import SwiftUI

struct Ball {
    var position: CGPoint
    var velocity: CGVector
    let size: CGFloat = 16
}

struct Paddle {
    var position: CGFloat // Center X
    let width: CGFloat = 120
    let height: CGFloat = 20
}

struct Brick: Identifiable {
    let id = UUID()
    var rect: CGRect
    var isHit: Bool = false
    var word: String? = nil // Optional word for display
    var icon: Icon? = nil   // Optional icon for display
}

struct BreakoutGameView: View {
    @State var server: String
    @EnvironmentObject var networkController: NetBrain
    @State private var ball = Ball(position: CGPoint(x: 300, y: 400), velocity: CGVector(dx: 4, dy: -6))
    @State private var paddle = Paddle(position: 300)
    @State private var bricks: [Brick] = []
    @State private var isGameRunning = false
    @State private var score = 0
    @State private var gameOver = false
    // --- New states for smooth paddle, pause, speed, and level ---
    @State private var leftPressed = false
    @State private var rightPressed = false
    @State private var isPaused = false
    @State private var speedLevel: Int = 10 // default to 10 per request (1-50)
    @State private var showLevelUp = false
    @State private var showIcons: Bool = true
    @State private var usedInitialIcons: Bool = false

    // Responsive frame size (updated from GeometryReader)
    @State private var frameSize: CGSize = CGSize(width: 600, height: 800)

    let rows = 5
    // Increase columns so more bricks fit across the width (bricks will be narrower)
    let cols = 12
    let brickWidth: CGFloat = 64
    let brickHeight: CGFloat = 24
    let paddleStep: CGFloat = 32

     @State private var words: [String] = []

     
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                bricksLayer()

                // Ball
                Circle()
                    .fill(Color.white)
                    .frame(width: ball.size, height: ball.size)
                    .position(ball.position)

                // Paddle
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
                    .frame(width: paddle.width, height: paddle.height)
                    .position(x: paddle.position, y: frameSize.height - 40)

                // toolbar moved into the score layer (so it appears above the Score text)

                scoreLayer()

                overlaysLayer()
            }
            .onAppear {
                // initialize frame size from geometry
                // Set frame size and initial positions on the main queue, then build bricks/words.
                DispatchQueue.main.async {
                    frameSize = geo.size
                    // Center paddle and ball relative to the initial size
                    paddle.position = frameSize.width / 2
                    ball.position = CGPoint(x: frameSize.width / 2, y: frameSize.height * 0.5)
                    setupBricks()
                    updateWords()
                }
                // If icons are desired by default and none are present, fetch them now.
                if showIcons && networkController.allIconsDetailed.isEmpty {
                    Task {
                        networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 200)
                        DispatchQueue.main.async { setupBricks() }
                    }
                }
                // Fetch policies in background
                Task {
                    try await networkController.getAllPolicies(server: server, authToken: networkController.authToken)
                }
            }
            .onChange(of: geo.size) { newSize in
                // Keep layout responsive when container size changes
                DispatchQueue.main.async {
                    frameSize = newSize
                    // Clamp paddle position to remain visible
                    paddle.position = min(max(paddle.width/2, paddle.position), frameSize.width - paddle.width/2)
                    // Clamp ball position to remain within the new frame
                    ball.position.x = max(ball.size/2, min(frameSize.width - ball.size/2, ball.position.x))
                    ball.position.y = max(ball.size/2, min(frameSize.height - ball.size/2, ball.position.y))
                    // Rebuild bricks for the new size
                    setupBricks()
                }
            }
            .frame(width: frameSize.width, height: frameSize.height)
         }
         // end GeometryReader
         .onChange(of: networkController.policies) { _ in
             updateWords()
         }
         .onChange(of: networkController.allIconsDetailed) { _ in
             // Rebuild bricks when icons list changes
             setupBricks()
         }
         .onReceive(Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()) { _ in
            guard isGameRunning && !gameOver && !isPaused else { return }
            updatePaddleSmoothly()
            updateGame()
        }
        .focusable()
        .onKeyDown { key in
            // Global keys that work regardless of running state
            if key == .reset {
                restartGame()
                return
            }
            if key == .toggleIcons {
                // Toggle icons and request icons if needed
                showIcons.toggle()
                if showIcons && networkController.allIconsDetailed.isEmpty {
                    networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 200)
                    DispatchQueue.main.async { setupBricks() }
                } else {
                    setupBricks()
                }
                return
            }

            // Space toggles pause when the game is running; if not running it starts the game
            if key == .space {
                if isGameRunning && !gameOver {
                    isPaused.toggle()
                } else if !isGameRunning && !gameOver {
                    isGameRunning = true
                }
                return
            }

            // Movement keys
            guard isGameRunning else { return }
            if key == .leftArrow {
               leftPressed = true
            } else if key == .rightArrow {
               rightPressed = true
            }
        }
        .onKeyUp { key in
           if key == .leftArrow {
               leftPressed = false
           } else if key == .rightArrow {
               rightPressed = false
           }
        }
    }

    // MARK: - Extracted subviews to reduce body complexity
    private func bricksLayer() -> AnyView {
        AnyView(
            ForEach(bricks) { brick in
                if !brick.isHit {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: brick.rect.width, height: brick.rect.height)
                        .overlay(
                            BrickContentView(brick: brick, showIcons: showIcons)
                        )
                        .position(x: brick.rect.midX, y: brick.rect.midY)
                }
            }
        )
    }

    private func scoreLayer() -> AnyView {
        AnyView(
            VStack {
                // Toolbar: contains buttons and controls and sits above the Score text
                HStack(spacing: 12) {
                    Button(isPaused ? "Resume" : "Pause") {
                        if isGameRunning && !gameOver {
                            isPaused.toggle()
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(!isGameRunning || gameOver)

                    Button("Reset") {
                        restartGame()
                    }
                    .keyboardShortcut("r", modifiers: [])

                    // Toggle to switch between words and icons
                    Toggle("Show Icons", isOn: $showIcons)
                        .toggleStyle(SwitchToggleStyle())
                        .keyboardShortcut("i", modifiers: [])
                        .onChange(of: showIcons) { enabled in
                            setupBricks()
                            if enabled && networkController.allIconsDetailed.isEmpty {
                                Task {
                                    // getAllIconsDetailed is a synchronous/non-throwing function in NetBrain,
                                    // so call it directly (no `try`/`await`).
                                    networkController.getAllIconsDetailed(server: server, authToken: networkController.authToken, loopTotal: 200)
                                    // rebuild bricks once icons are fetched
                                    DispatchQueue.main.async {
                                        setupBricks()
                                    }
                                }
                            }
                        }

                    if !isGameRunning && !gameOver {
                        Picker("Speed", selection: $speedLevel) {
                            ForEach(1...50, id: \.self) { level in
                                Text("Level \(level)")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 140)
                    }

                    Spacer()
                }
                .padding(8)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(8)
                .padding([.leading, .trailing, .top], 8)

                HStack {
                    Spacer()
                    Text("Score: \(score)")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                }
                .padding()

                Spacer()
            }
         )
     }

    private func overlaysLayer() -> AnyView {
         AnyView(
             Group {
                 if showLevelUp {
                     VStack {
                         Spacer()
                         VStack {
                             Text("Level Up! Speed: \(speedLevel)")
                                 .foregroundColor(.yellow)
                                 .font(.title)
                                 .padding()
                         }
                         .background(Color.black.opacity(0.8))
                         .cornerRadius(16)
                         .padding(.bottom, 80)
                     }
                 }
                 if !isGameRunning || gameOver {
                     VStack {
                         Spacer()
                         VStack {
                             Text(gameOver ? "Game Over" : "Icon Breaker")
                                 .foregroundColor(.white)
                                 .font(.largeTitle)
                                 .padding()
                             if !gameOver {
                                 Text("Press SPACE to Start")
                                     .foregroundColor(.white)
                                     .padding()
                             }
                             if gameOver {
                                 Text("Final Score: \(score)")
                                     .foregroundColor(.white)
                                     .padding()
                                 Button("Restart") {
                                     restartGame()
                                 }
                                 .keyboardShortcut(.space, modifiers: [])
                                 .padding()
                             }
                         }
                         .background(Color.black.opacity(0.8))
                         .cornerRadius(16)
                         .padding(.bottom, 80)
                     }
                 }
             }
         )
     }
    
    private func updateWords() {
        // Map networkController.policies ([Policy]) to [String] by using the 'name' property.
        if networkController.policies.isEmpty {
            words = []
        } else {
            words = networkController.policies.map { $0.name }.shuffled()
            print("Words are:\(words)")
        }
        // Rebuild bricks so the new words are applied to brick.word
        DispatchQueue.main.async {
            setupBricks()
        }
    }
 // --- Smooth paddle movement ---
    private func updatePaddleSmoothly() {
        let smoothStep: CGFloat = 8
        if leftPressed {
            paddle.position = max(paddle.width/2, paddle.position - smoothStep)
        }
        if rightPressed {
            paddle.position = min(frameSize.width - paddle.width/2, paddle.position + smoothStep)
        }
    }
    
    private func setupBricks() {
        bricks = []
        // Compute brick size dynamically so blocks are larger and fit nicely in the view.
        let horizontalPadding: CGFloat = max(12, frameSize.width * 0.04)
        let availableWidth = max(100, frameSize.width - horizontalPadding * 2)
        // Make bricks bigger but keep sensible min/max.
        // Use a smaller width per brick to allow more columns, but increase height to make icons larger.
        let brickW = max(28, min(availableWidth / CGFloat(cols) - 6, 120))
        // Make bricks taller so icons have more vertical space (icons will appear larger)
        let brickH = max(34, brickW * 0.75)
        let xOffset: CGFloat = (frameSize.width - (CGFloat(cols) * brickW)) / 2
        var wordIndex = 0
        for row in 0..<rows {
            for col in 0..<cols {
                let rect = CGRect(
                    x: xOffset + CGFloat(col) * brickW,
                    y: max(40, frameSize.height * 0.06) + CGFloat(row) * brickH,
                    width: brickW - 6,
                    height: brickH - 6
                )
                if showIcons {
                    // Assign icons (cycle through available icons)
                    if networkController.allIconsDetailed.isEmpty {
                        bricks.append(Brick(rect: rect, word: nil, icon: nil))
                    } else {
                        // Use the first batch of icons (in order) the very first time we populate icons.
                        // On subsequent runs, pick random icons for variety.
                        let icons = networkController.allIconsDetailed
                        let icon: Icon
                        if !usedInitialIcons {
                            icon = icons[wordIndex % icons.count]
                        } else {
                            icon = icons.randomElement() ?? icons[wordIndex % icons.count]
                        }
                        bricks.append(Brick(rect: rect, word: nil, icon: icon))
                    }
                } else {
                    let word: String?
                    if words.isEmpty {
                        word = nil
                    } else {
                        // Cycle through words so all bricks receive a label
                        word = words[wordIndex % words.count]
                    }
                    bricks.append(Brick(rect: rect, word: word, icon: nil))
                }
                wordIndex += 1
            }
        }
        // If we just populated icons for the first time, mark that we've used the initial set so
        // subsequent calls will use random selections instead.
        if showIcons && !networkController.allIconsDetailed.isEmpty && !usedInitialIcons {
            usedInitialIcons = true
        }
    }
    
    private func updateGame() {
        // Move ball
        let speedMultiplier = CGFloat(speedLevel) / 10.0 // 0.1 (slow) to 5.0 (fast)
        var newPos = CGPoint(
            x: ball.position.x + ball.velocity.dx * speedMultiplier,
            y: ball.position.y + ball.velocity.dy * speedMultiplier
        )
        
        // Wall collisions
        if newPos.x <= ball.size/2 || newPos.x >= frameSize.width - ball.size/2 {
            ball.velocity.dx *= -1
            newPos.x = max(ball.size/2, min(frameSize.width - ball.size/2, newPos.x))
        }
        if newPos.y <= ball.size/2 {
            ball.velocity.dy *= -1
            newPos.y = ball.size/2
        }
        
        // Paddle collision
        let paddleRect = CGRect(
            x: paddle.position - paddle.width/2,
            y: frameSize.height - 40 - paddle.height/2,
            width: paddle.width,
            height: paddle.height
        )
        let ballRect = CGRect(
             x: newPos.x - ball.size/2,
             y: newPos.y - ball.size/2,
             width: ball.size,
             height: ball.size
         )
        if ballRect.intersects(paddleRect) && ball.velocity.dy > 0 {
            ball.velocity.dy *= -1
            // Add a little horizontal angle based on hit location
            let hit = (newPos.x - paddle.position) / (paddle.width/2)
            ball.velocity.dx += hit * 2
            // Clamp speed
            let speed = sqrt(ball.velocity.dx * ball.velocity.dx + ball.velocity.dy * ball.velocity.dy)
            let maxSpeed: CGFloat = 8
            if speed > maxSpeed {
                ball.velocity.dx *= maxSpeed/speed
                ball.velocity.dy *= maxSpeed/speed
            }
            newPos.y = frameSize.height - 40 - paddle.height/2 - ball.size/2
        }
        
        // Brick collisions
        for i in bricks.indices {
            if bricks[i].isHit { continue }
            if ballRect.intersects(bricks[i].rect) {
                bricks[i].isHit = true
                score += 10
                ball.velocity.dy *= -1
                break
            }
        }
        
        ball.position = newPos
        
        // Lose condition
        if ball.position.y > frameSize.height + ball.size {
            gameOver = true
            isGameRunning = false
        }
        
        // Win condition
        if bricks.allSatisfy({ $0.isHit }) {
            // Level up: increase speed, reset bricks/ball/paddle, show overlay
            if speedLevel < 50 { speedLevel += 1 }
            showLevelUp = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showLevelUp = false
                nextLevel()
            }
        }
    }
    // --- Next level logic ---
    private func nextLevel() {
        // Center ball and paddle relative to current frame size for responsive layouts
        ball = Ball(position: CGPoint(x: frameSize.width / 2, y: frameSize.height * 0.5), velocity: CGVector(dx: 4, dy: -6))
        paddle = Paddle(position: frameSize.width / 2)
        setupBricks()
        isGameRunning = true
        gameOver = false
    }
    
    private func restartGame() {
        // Reset ball and paddle centered in the current frame so the UI stays consistent when resized
        ball = Ball(position: CGPoint(x: frameSize.width / 2, y: frameSize.height * 0.5), velocity: CGVector(dx: 4, dy: -6))
        paddle = Paddle(position: frameSize.width / 2)
        setupBricks()
        score = 0
        gameOver = false
        isGameRunning = false
        speedLevel = 10
        // Do not reset usedInitialIcons here — user wanted the first run to use the first icons fetched.
     }

 }

// --- Keyboard handling for SwiftUI on macOS ---

// Use a small, SDK-compatible Key enum instead of KeyEquivalent so we don't rely on
// macOS 14+ Equatable implementations of KeyEquivalent.
fileprivate enum KeyPress: Equatable {
    case leftArrow
    case rightArrow
    case space
    case reset
    case toggleIcons
}

// This view modifier allows keyboard events in SwiftUI for macOS.
fileprivate struct KeyDownModifier: ViewModifier {
    let action: (KeyPress) -> Void

    func body(content: Content) -> some View {
        content
            .background(KeyEventHandlingView(action: action))
    }

    struct KeyEventHandlingView: NSViewRepresentable {
        let action: (KeyPress) -> Void

        func makeNSView(context: Context) -> NSView {
            // NSView subclass that accepts first responder and forwards key events
            class KeyCatcherView: NSView {
                var onKeyDown: ((NSEvent) -> Void)?
                override var acceptsFirstResponder: Bool { true }
                override func keyDown(with event: NSEvent) {
                    onKeyDown?(event)
                }
                override func viewDidMoveToWindow() {
                    super.viewDidMoveToWindow()
                    // Request first responder in the window when available
                    window?.makeFirstResponder(self)
                }
            }

            let view = KeyCatcherView()
            view.onKeyDown = { event in
                if let key = KeyPress(event: event) {
                    action(key)
                }
            }

            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}
        func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {}
        func makeCoordinator() -> Coordinator { Coordinator() }
        class Coordinator {}
    }
}

extension View {
    fileprivate func onKeyDown(_ action: @escaping (KeyPress) -> Void) -> some View {
        self.modifier(KeyDownModifier(action: action))
    }
}

// Add onKeyUp modifier for key release
extension View {
    fileprivate func onKeyUp(_ action: @escaping (KeyPress) -> Void) -> some View {
        self.background(KeyUpEventHandlingView(action: action))
    }
}
fileprivate struct KeyUpEventHandlingView: NSViewRepresentable {
    let action: (KeyPress) -> Void
    func makeNSView(context: Context) -> NSView {
        class KeyCatcherView: NSView {
            var onKeyUp: ((NSEvent) -> Void)?
            override var acceptsFirstResponder: Bool { true }
            override func keyUp(with event: NSEvent) {
                onKeyUp?(event)
            }
            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                window?.makeFirstResponder(self)
            }
        }

        let view = KeyCatcherView()
        view.onKeyUp = { event in
            if let key = KeyPress(event: event) {
                action(key)
            }
        }
        return view
     }
     func updateNSView(_ nsView: NSView, context: Context) {}
     func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {}
     func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator {}
}

// Map NSEvent to our KeyPress enum. Prefer character matching for letters so layout-agnostic.
fileprivate extension KeyPress {
    init?(event: NSEvent) {
        // Check letters/space via charactersIgnoringModifiers
        if let chars = event.charactersIgnoringModifiers?.lowercased() {
            if chars == "r" { self = .reset; return }
            if chars == "i" { self = .toggleIcons; return }
            if chars == " " { self = .space; return }
        }
        // Fall back to arrow keycodes
        switch event.keyCode {
        case 123: self = .leftArrow
        case 124: self = .rightArrow
        case 49:  self = .space
        default: return nil
        }
    }
}

// New small view to render brick content (word or icon). Extracted to simplify the parent view.
fileprivate struct BrickContentView: View {
    let brick: Brick
    let showIcons: Bool

    @ViewBuilder
    var body: some View {
        if showIcons, let icon = brick.icon, let url = URL(string: icon.url) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        // Size the image to the brick's rect so icons appear larger and fill the brick.
                        .frame(width: max(24, brick.rect.width * 0.92), height: max(24, brick.rect.height * 0.92))
                        .padding(4)
                case .failure(_):
                    Image(systemName: "xmark.octagon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: max(16, brick.rect.width * 0.8), height: max(16, brick.rect.height * 0.8))
                        .padding(8)
                default:
                    ProgressView()
                }
            }
        } else if let word = brick.word {
            Text(word)
                .foregroundColor(.black)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 4)
        } else {
            EmptyView()
        }
    }
}
