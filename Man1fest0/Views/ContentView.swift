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
}

struct BreakoutGameView: View {
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
    @State private var speedLevel: Int = 1 // 1 (slowest) to 50 (fastest)
    @State private var showLevelUp = false
    
    let rows = 5
    let cols = 8
    let brickWidth: CGFloat = 64
    let brickHeight: CGFloat = 24
    let paddleStep: CGFloat = 32
    let frameWidth: CGFloat = 600
    let frameHeight: CGFloat = 800
    
    @State private var words: [String] = [
        "Swift", "Code", "Game", "Fun", "Brick", "Ball", "Paddle", "Break"
    ] // Example words, can be set by user
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Bricks
            ForEach(bricks) { brick in
                if !brick.isHit {
                    ZStack {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: brick.rect.width, height: brick.rect.height)
                            .position(x: brick.rect.midX, y: brick.rect.midY)
                        if let word = brick.word {
                            Text(word)
                                .foregroundColor(.black)
                                .font(.system(size: 14, weight: .bold))
                                .position(x: brick.rect.midX, y: brick.rect.midY)
                        }
                    }
                }
            }
            
            // Ball
            Circle()
                .fill(Color.white)
                .frame(width: ball.size, height: ball.size)
                .position(ball.position)
            
            // Paddle
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue)
                .frame(width: paddle.width, height: paddle.height)
                .position(x: paddle.position, y: frameHeight - 40)
            
            // Score
            VStack {
                HStack {
                    Text("Score: \(score)")
                        .foregroundColor(.white)
                        .font(.headline)
                    Spacer()
                }
                .padding()
                Spacer()
            }
            
            // Pause button and speed picker
            VStack {
                HStack {
                    Button(isPaused ? "Resume" : "Pause") {
                        if isGameRunning && !gameOver {
                            isPaused.toggle()
                        }
                    }
                    .padding(.trailing, 8)
                    .disabled(!isGameRunning || gameOver)
                    if !isGameRunning && !gameOver {
                        Picker("Speed", selection: $speedLevel) {
                            ForEach(1...50, id: \.self) { level in
                                Text("Level \(level)")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                        .padding(.trailing, 8)
                    }
                    Spacer()
                }
                .padding(.top, 8)
                Spacer()
            }
            // Level up overlay
            if showLevelUp {
                VStack {
                    Text("Level Up! Speed: \(speedLevel)")
                        .foregroundColor(.yellow)
                        .font(.title)
                        .padding()
                }
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
            }
            
            if !isGameRunning || gameOver {
                VStack {
                    Text(gameOver ? "Game Over" : "Breakout")
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
            }
        }
        .frame(width: frameWidth, height: frameHeight)
        .onAppear {
            setupBricks()
        }
        .onReceive(Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()) { _ in
            guard isGameRunning && !gameOver && !isPaused else { return }
            updatePaddleSmoothly()
            updateGame()
        }
        .focusable()
        .onKeyDown { key in
            guard isGameRunning else {
                if key == .space && !gameOver { isGameRunning = true }
                return
            }
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
    // --- Smooth paddle movement ---
    private func updatePaddleSmoothly() {
        let smoothStep: CGFloat = 8
        if leftPressed {
            paddle.position = max(paddle.width/2, paddle.position - smoothStep)
        }
        if rightPressed {
            paddle.position = min(frameWidth - paddle.width/2, paddle.position + smoothStep)
        }
    }
    
    private func setupBricks() {
        bricks = []
        let xOffset: CGFloat = (frameWidth - (CGFloat(cols) * brickWidth)) / 2
        var wordIndex = 0
        for row in 0..<rows {
            for col in 0..<cols {
                let rect = CGRect(
                    x: xOffset + CGFloat(col) * brickWidth,
                    y: 60 + CGFloat(row) * brickHeight,
                    width: brickWidth - 4,
                    height: brickHeight - 4
                )
                let word: String? = wordIndex < words.count ? words[wordIndex] : nil
                bricks.append(Brick(rect: rect, word: word))
                wordIndex += 1
            }
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
        if newPos.x <= ball.size/2 || newPos.x >= frameWidth - ball.size/2 {
            ball.velocity.dx *= -1
            newPos.x = max(ball.size/2, min(frameWidth - ball.size/2, newPos.x))
        }
        if newPos.y <= ball.size/2 {
            ball.velocity.dy *= -1
            newPos.y = ball.size/2
        }
        
        // Paddle collision
        let paddleRect = CGRect(
            x: paddle.position - paddle.width/2,
            y: frameHeight - 40 - paddle.height/2,
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
            newPos.y = frameHeight - 40 - paddle.height/2 - ball.size/2
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
        if ball.position.y > frameHeight + ball.size {
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
        ball = Ball(position: CGPoint(x: 300, y: 400), velocity: CGVector(dx: 4, dy: -6))
        paddle = Paddle(position: 300)
        setupBricks()
        isGameRunning = true
        gameOver = false
    }
    
    private func restartGame() {
        ball = Ball(position: CGPoint(x: 300, y: 400), velocity: CGVector(dx: 4, dy: -6))
        paddle = Paddle(position: 300)
        setupBricks()
        score = 0
        gameOver = false
        isGameRunning = false
        speedLevel = 1
    }
}

// --- Keyboard handling for SwiftUI on macOS ---

// This view modifier allows keyboard events in SwiftUI for macOS.
fileprivate struct KeyDownModifier: ViewModifier {
    let action: (KeyEquivalent) -> Void

    func body(content: Content) -> some View {
        content
            .background(KeyEventHandlingView(action: action))
    }

    struct KeyEventHandlingView: NSViewRepresentable {
        let action: (KeyEquivalent) -> Void

        func makeNSView(context: Context) -> NSView {
            let view = NSView()
            let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if let key = KeyEquivalent(event: event) {
                    action(key)
                }
                return event
            }
            context.coordinator.monitor = monitor
            return view
        }
        func updateNSView(_ nsView: NSView, context: Context) {}
        func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            if let monitor = coordinator.monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
        func makeCoordinator() -> Coordinator { Coordinator() }
        class Coordinator {
            var monitor: Any?
        }
    }
}

extension View {
    func onKeyDown(_ action: @escaping (KeyEquivalent) -> Void) -> some View {
        self.modifier(KeyDownModifier(action: action))
    }
}

// Add onKeyUp modifier for key release
extension View {
    func onKeyUp(_ action: @escaping (KeyEquivalent) -> Void) -> some View {
        self.background(KeyUpEventHandlingView(action: action))
    }
}
fileprivate struct KeyUpEventHandlingView: NSViewRepresentable {
    let action: (KeyEquivalent) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            if let key = KeyEquivalent(event: event) {
                action(key)
            }
            return event
        }
        context.coordinator.monitor = monitor
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
    func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        if let monitor = coordinator.monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator {
        var monitor: Any?
    }
}

// Map NSEvent to KeyEquivalent
fileprivate extension KeyEquivalent {
    init?(event: NSEvent) {
        switch event.keyCode {
        case 123: self = .leftArrow
        case 124: self = .rightArrow
        case 49:  self = .space
        default: return nil
        }
    }
}

fileprivate extension KeyEquivalent {
    static let leftArrow = KeyEquivalent(Character(UnicodeScalar(NSLeftArrowFunctionKey)!))
    static let rightArrow = KeyEquivalent(Character(UnicodeScalar(NSRightArrowFunctionKey)!))
}
