import SwiftUI
import PencilKit
import UIKit
import Combine // Required for ObservableObject and @Published

// MARK: - 1. PKCanvasView Wrapper (UIKit to SwiftUI)

// We make this an ObservableObject to manage the tool picker's state
class DrawingState: ObservableObject {
    @Published var isToolPickerVisible: Bool = true
    @Published var drawing = PKDrawing()
    
    // PKToolPicker is now managed as a regular instance, not a shared singleton
    var toolPicker: PKToolPicker? = nil
}

// UIViewRepresentable is how we bridge the UIKit component (PKCanvasView) into SwiftUI
struct DrawingCanvasView: UIViewRepresentable {
    @ObservedObject var state: DrawingState
    
    typealias UIViewType = PKCanvasView
    
    func makeUIView(context: Context) -> UIViewType {
        let canvasView = PKCanvasView()
        
        // 1. Configure the Canvas View for Apple Notes Look/Feel
        canvasView.drawing = state.drawing
        canvasView.isOpaque = true
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator // Set the delegate to capture changes
        
        // 2. Set up and observe the PKToolPicker (the floating toolbar)
        DispatchQueue.main.async {
            
            // 💡 Create a new instance of PKToolPicker()
            let toolPicker = PKToolPicker()
            
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(context.coordinator) // Observe visibility changes
            
            // Set visibility
            toolPicker.setVisible(self.state.isToolPickerVisible, forFirstResponder: canvasView)
            
            // Store the toolPicker reference in the ObservableObject
            self.state.toolPicker = toolPicker

            // FIX: Delay the call to becomeFirstResponder() for better stability on initial load.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Make the canvas the first responder to activate the picker
                canvasView.becomeFirstResponder()
            }
        }
        
        return canvasView
    }
    
    // Updates the view when the SwiftUI state changes
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // This keeps the tool picker visibility synchronized with the SwiftUI state
        state.toolPicker?.setVisible(state.isToolPickerVisible, forFirstResponder: uiView)
        
        // Ensure the drawing property is updated from the state
        if uiView.drawing != state.drawing {
            uiView.drawing = uiView.drawing // Intentional use of self assignment to avoid race condition/infinite loop
        }
    }
    
    // Coordinator acts as the delegate to communicate changes from UIKit (PKCanvasView) back to SwiftUI
    func makeCoordinator() -> Coordinator {
        Coordinator(state: state)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        var state: DrawingState
        
        init(state: DrawingState) {
            self.state = state
        }
        
        // Delegate method that fires when the drawing content changes
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Update the state's drawing property
            state.drawing = canvasView.drawing
        }
        
        // Delegate method that fires when the tool picker's visibility changes
        func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
            // Synchronize the SwiftUI state with the actual visibility
            state.isToolPickerVisible = toolPicker.isVisible
        }
    }
}

// MARK: - 2. SwiftUI Main Content View

struct ContentView: View {
    @StateObject private var drawingState = DrawingState()
    
    var body: some View {
        // Use a NavigationStack for the title and toolbar look
        NavigationStack {
            // Embed the custom drawing canvas
            DrawingCanvasView(state: drawingState)
                .edgesIgnoringSafeArea(.all)
                .toolbar {
                    // Toolbar Item to show/hide the tool picker, just like in Notes
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            // Toggle the visibility of the tool picker
                            drawingState.isToolPickerVisible.toggle()
                        } label: {
                            // Use the pencil icon (like the Notes app)
                            Image(systemName: "scribble.variable")
                        }
                    }
                    
                    // Toolbar item for a basic "Clear" function (like a simple 'Undo')
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear") {
                            // Clear the drawing by setting it to a new empty drawing
                            drawingState.drawing = PKDrawing()
                        }
                    }
                }
                .navigationTitle("PencilKit Sketch") // A title for the view
                // Simplified background color for compatibility
                .background(Color.white.opacity(0.95))
        }
    }
}

#Preview {
    ContentView()
}
