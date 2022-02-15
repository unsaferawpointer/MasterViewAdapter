//
//  OutlineViewAdapter.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 01.01.2022.
//

import Foundation
import AppKit

public protocol OutlineCellModel: Identifiable {
	associatedtype Value
	var isSelectable: Bool { get }
	var allowReorder: Bool { get }
	var tintColor: NSColor? { get }
	var isEditable: Bool { get }
}

public protocol OutlineCellPresentable: NSTableCellView {
	associatedtype Model: OutlineCellModel
	var model: Model? { get set }
	var valueDidChanged: ((Model.Value) -> Void)? { get set }
	init()
}

/* NSOutlineView adapter for flatten hierarchy of the data
 contains:
 * header menu section
 * divider
 * item list section || Empty View
 * divider
 * footer menu section
 */
public class MasterViewAdapter<BasicCell: OutlineCellPresentable>: NSObject,
															NSOutlineViewDataSource,
															NSOutlineViewDelegate {
	
	public typealias Model = BasicCell.Model
	
	var outlineView: NSOutlineView
	
	/// Perform every time while selection did changed
	public var selectionProvider: ((Model.ID) -> Void)?
	
	public var valueDidChanged: ((Model.ID, Model.Value) -> Void)?
	/// First arguments is moving Model.ID, second - Model.ID before moving model
	public var reorderProvider: ((Model.ID, Model.ID) -> Void)?
	
	var draggedType: NSPasteboard.PasteboardType?
	
	public var onDropProvider: ((Model.ID, Any) -> Void)?
	
	var isEditing: Bool = false
	
	var topBoundary: Int = 0
	var bottomBoundary: Int = 0
	
	private var data: [OutlineItem]  = []

	/// Convert  BasicCell.Model -> Cell
	private func configureTargetCollection(listItems: [Model], header: [Model] = [], footer: [Model] = []) -> [Cell] {
		var target = header.map { model in
			Cell.basic(model: model)
		}

		topBoundary = header.count
		bottomBoundary = header.count

		if listItems.isEmpty == false {
			target += [Cell.divider(.header)]
			target += listItems.map { model in
				Cell.basic(model: model)
			}
			bottomBoundary = topBoundary + listItems.count + 2
		} else {
			target += [Cell.divider(.header)]
			target += [.placeholder]
			
			bottomBoundary = topBoundary + 3
		}

		if footer.isEmpty == false {
			target += [Cell.divider(.header)]
			target += footer.map { model in
				Cell.basic(model: model)
			}
		}
		return target
	}
	
	private func configureSourceCollection() -> [Cell] {
		return data.map(\.cell)
	}
	
	public func apply(listItems: [Model], header: [Model] = [], footer: [Model] = []) {

		let target = configureTargetCollection(listItems: listItems, header: header, footer: footer)
		let source = configureSourceCollection()

		let diff = target.difference(from: source).inferringMoves()

		var removedCache: [AnyHashable: OutlineItem] = [:]

		outlineView.beginUpdates()
		for change in diff {
			switch change {
				case .remove(let offset, let element, _):
					let removed = data.remove(at: offset)
					removedCache[element.id] = removed
					outlineView.removeItems(at: .init(integer: offset), inParent: nil, withAnimation: [.effectFade, .effectGap])
				case .insert(let offset, let element, _):
					if let moved = removedCache[element.id] {
						data.insert(moved, at: offset)
					} else {
						data.insert(.init(element), at: offset)
					}
					outlineView.insertItems(at: .init(integer: offset), inParent: nil, withAnimation: [.effectFade, .effectGap])
			}
		}
		outlineView.endUpdates()
	}
	
	public var selectedItem: Model.ID? {
		
		let selectedRow = outlineView.selectedRow
		guard
			selectedRow > -1,
			let outlineItem = outlineView.item(atRow: selectedRow) as? OutlineItem,
			case let Cell.basic(model) = outlineItem.cell
		else {
			return nil
		}
		
		return model.id
	}
	
	public init(outlineView: NSOutlineView, draggedType: NSPasteboard.PasteboardType) {
		self.outlineView = outlineView
		super.init()
		outlineView.delegate = self
		outlineView.dataSource = self
		outlineView.registerForDraggedTypes([.reorder, draggedType])
	}
	
	public func outlineViewSelectionDidChange(_ notification: Notification) {
		let selectedRow = outlineView.selectedRow
		guard
			selectedRow > -1,
			let outlineItem = outlineView.item(atRow: selectedRow) as? OutlineItem,
			case let Cell.basic(model) = outlineItem.cell
		else {
			return
		}
		selectionProvider?(model.id)
	}
	
	public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		return data.count
	}
	
	public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		return data[index]
	}
	
	public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		return false
	}
	
	public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
		return false
	}
	
	public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		
		if let outlineItem = item as? OutlineItem {
			
			switch outlineItem.cell {
				case .basic(let model):
					let viewID = NSUserInterfaceItemIdentifier("outline.basic")
					var cell = outlineView.makeView(withIdentifier: viewID, owner: self) as? BasicCell
					if cell == nil {
						cell = BasicCell()
						cell?.identifier = viewID
					}
					cell?.model = model
					cell?.valueDidChanged = { [weak self] (newValue) in
						self?.valueDidChanged?(model.id, newValue)
					}
					return cell
				case .placeholder:
					let container = NSView(frame: .init(origin: .zero, size: .init(width: outlineView.bounds.width, height: 120.0)))
					let label = NSTextField(frame: container.bounds)
					label.autoresizingMask = [.width]
					label.lineBreakMode = .byTruncatingTail
					label.stringValue = "Please, add list..."
					label.isBordered = false
					label.drawsBackground = false
					label.textColor = .secondaryLabelColor
					label.font = NSFont.preferredFont(forTextStyle: .callout, options: [:])
					container.addSubview(label)
					return container
				case .divider: do {
					let viewID = NSUserInterfaceItemIdentifier("outline.divider")
					var cell = outlineView.makeView(withIdentifier: viewID, owner: self) as? DividerCell
					if cell == nil {
						cell = DividerCell()
						cell?.identifier = viewID
					}
					return cell
				}
			}
		}
		return nil
	}
	
	public func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
		if let outlineItem = item as? OutlineItem {
			return outlineItem.isSelectable
		}
		return false
	}
	
	public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
		if let outlineItem = item as? OutlineItem, case .placeholder = outlineItem.cell {
			return 120.0
		}
		return outlineView.rowHeight
	}
	
	public func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
		if let outlineItem = item as? OutlineItem, case let .basic(model) = outlineItem.cell {
			return model.isEditable
		}
		return false
	}
	
	public func outlineView(_ outlineView: NSOutlineView, tintConfigurationForItem item: Any) -> NSTintConfiguration? {
		guard
			let outlineItem = item as? OutlineItem,
			case let .basic(model) = outlineItem.cell,
			let color = model.tintColor
		else {
			return .monochrome
		}
		return .init(preferredColor: color)
	}
	
	/*
	 Drag And Drop Support
	 */
	
	// swiftlint:disable line_length
	public func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
		
		if isLocalSource(draggingInfo: info) {
			guard index > topBoundary && index < bottomBoundary else { return [] }
			return .move
		} else if
			index == -1,
			let outlineItem = item as? OutlineItem,
			case .basic = outlineItem.cell {
			
			return .move
		}
		
		return []
	}
	
	public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
		
		guard
			let outlineItem = item as? OutlineItem,
			case .basic = outlineItem.cell
		else {
			return nil
		}
		
		let item = NSPasteboardItem()
		let index = data.firstIndex { item in
			item === outlineItem
		}
		
		guard let index = index else {
			return nil
		}
		
		guard let data = try? NSKeyedArchiver.archivedData(withRootObject: index, requiringSecureCoding: true) else {
			return nil
		}
		
		item.setData(data, forType: .reorder)
		return item
	}
	
	public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
		
		if isLocalSource(draggingInfo: info) {
			
			return performReoder(with: info, childIndex: index)
		} else if
			index == -1,
			let outlineItem = item as? OutlineItem,
			case let .basic(model) = outlineItem.cell {
			
			return performDrop(model.id, with: info)
		}
		
		return false
	}
	
	private func performReoder(with draggingInfo: NSDraggingInfo, childIndex index: Int) -> Bool {
		
		let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems ?? []
		
		var moved: Int?
		
		if let data = pasteboardItems.first?.data(forType: .reorder) {
			moved = NSKeyedUnarchiver.unarchiveObject(with: data) as? Int
		}
		
		if let removedIndex = moved {
			
			let outlineItem = data.remove(at: removedIndex)
			if removedIndex > index {
				data.insert(outlineItem, at: index)
				outlineView.moveItem(at: removedIndex, inParent: nil, to: index, inParent: nil)
			} else {
				data.insert(outlineItem, at: index - 1)
				outlineView.moveItem(at: removedIndex, inParent: nil, to: index - 1, inParent: nil)
			}
			return true
		}
		
		return false
	}
	
	private func performDrop(_ id: BasicCell.Model.ID, with draggingInfo: NSDraggingInfo) -> Bool {

		guard let draggedType = draggedType else {
			return false
		}

		let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems ?? []
		if let data = pasteboardItems.first?.data(forType: draggedType) {
			let identifiers = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UUID]
			onDropProvider?(id, identifiers)
			return true
		}
		return false
	}
	
	
	func isLocalSource(draggingInfo info: NSDraggingInfo) -> Bool {
		if let source = info.draggingSource as? NSOutlineView, source === outlineView {
			return true
		}
		return false
	}
	
	//	private func movedIdentifiers(from draggingInfo: NSDraggingInfo) -> [UUID] {
	//
	//		var movedIndexSet: [UUID]?
	//
	//		let pasteboardItems = draggingInfo.draggingPasteboard.pasteboardItems ?? []
	//		if let data = pasteboardItems.first?.data(forType: .reorder) {
	//			movedIndexSet = NSKeyedUnarchiver.unarchiveObject(with: data) as? [UUID]
	//		}
	//		return movedIndexSet ?? []
	//	}
	
	
}

extension MasterViewAdapter {
	
	enum Cell: Hashable {
		
		static func == (lhs: Cell, rhs: Cell) -> Bool {
			return lhs.id == rhs.id
		}
		
		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
		}
		
		enum DividerLocation {
			case header
			case footer
		}
		
		/// Divider between sections
		case divider(_ id: DividerLocation)
		/// icon - title cell
		case basic(model: Model)
		/// OutlineView show placeholder, when list data is empty
		case placeholder
		
		var id: AnyHashable {
			switch self {
				case .divider(let id):
					return id
				case .basic(let model):
					return model.id
				case .placeholder:
					return "placeholder"
			}
		}
	}
	
	/// Reference - type wrapper of the NSOulineView item
	class OutlineItem {
		
		var cell: Cell
		
		init(_ cell: Cell) {
			self.cell = cell
		}
		
		var isSelectable: Bool {
			switch cell {
				case .divider, .placeholder:
					return false
				case .basic(let model):
					return  model.isSelectable
			}
		}
		
		var allowReorder: Bool {
			switch cell {
				case .divider, .placeholder:
					return false
				case .basic(let model):
					return model.allowReorder
			}
		}
		
	}
	
}

private extension NSPasteboard.PasteboardType {
	static var reorder = NSPasteboard.PasteboardType("private.outlineview.reorder")
}
