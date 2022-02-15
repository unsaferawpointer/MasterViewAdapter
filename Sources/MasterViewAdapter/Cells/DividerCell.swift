//
//  DividerCell.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 11.02.2022.
//

import Cocoa

public class DividerCell: NSTableCellView {

	required init() {
		super.init(frame: .zero)
		configureUI()
	}

	@available(*, unavailable, message: "Use init()")
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func configureUI() {
		let dividerWidth = bounds.width
		let dividerHeight = 2.0
		let size = CGSize(width: dividerWidth, height: dividerHeight)
		let originY = (bounds.height - dividerHeight)/2
		let origin = CGPoint(x: 0, y: originY)
		let dividerView = DividerView(frame: .init(origin: origin, size: size))
		dividerView.translatesAutoresizingMaskIntoConstraints = false
//		dividerView.autoresizingMask = [.width]
		addSubview(dividerView)
		NSLayoutConstraint.activate([
			dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
			dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
			dividerView.centerYAnchor.constraint(equalTo: centerYAnchor)
		])
	}

}
