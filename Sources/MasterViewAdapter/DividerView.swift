//
//  DividerView.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 08.02.2022.
//

import AppKit

public enum DividerAxis {
	case horizontal
	case vertical
}

public class DividerView: NSView {

	var color: NSColor = .init(white: 0.5, alpha: 0.3)

	public override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
		color.setFill()
		dirtyRect.fill()
	}

//	// MARK: - Properties
//
//	open var axis = DividerAxis.horizontal {
//		didSet {
//			invalidateIntrinsicContentSize()
//		}
//	}
//
//	@IBInspectable var vertical: Bool {
//		get {
//			return axis == .vertical
//		}
//		set {
//			axis = (newValue ? .vertical : .horizontal)
//		}
//	}
//
//	fileprivate var thickness: CGFloat = 1 {
//		didSet {
//			invalidateIntrinsicContentSize()
//		}
//	}
//
//	// MARK: - Methods
//
//	public convenience init(axis: DividerAxis) {
//		self.init(frame: .zero)
//		self.axis = axis
//	}
//
//	override init(frame: CGRect) {
//		super.init(frame: frame)
////		setupRequiredContentHuggingPriority()
//	}
//
//	required public init?(coder aDecoder: NSCoder) {
//		super.init(coder: aDecoder)
////		setupRequiredContentHuggingPriority()
//	}
//
////	fileprivate func setupRequiredContentHuggingPriority() {
////		setContentHuggingPriority(.required, for: .vertical)
////		setContentHuggingPriority(.required, for: .horizontal)
////	}
//
//	fileprivate func updateThicknessForWindow(_ window: NSWindow?) {
//		#if !TARGET_INTERFACE_BUILDER
//		let screen = window?.screen ?? NSScreen.main
//		thickness = 1 /// (screen?.backingScaleFactor ?? 1.0)
//		#else
//		thickness = 1
//		#endif
//	}
//
//	open override func viewWillMove(toWindow newWindow: NSWindow?) {
//		super.viewWillMove(toWindow: newWindow)
//		updateThicknessForWindow(newWindow)
//	}
//
	override open var intrinsicContentSize: CGSize {
		return CGSize(width: NSView.noIntrinsicMetric, height: 1.2)
	}
}
