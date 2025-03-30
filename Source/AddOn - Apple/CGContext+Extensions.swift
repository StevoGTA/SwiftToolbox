//
//  CGContext+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 6/19/20.
//

import CoreGraphics

//----------------------------------------------------------------------------------------------------------------------
// MARK: CGContext extension
extension CGContext {

	// Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func drawDash(width :CGFloat, phase :CGFloat = 0.0, lengths :[CGFloat], in rect :CGRect, color :CGColor,
			drawingMode :CGPathDrawingMode = .stroke) {
		// Setup Context
		saveGState()

		setLineWidth(width)
		setLineDash(phase: phase, lengths: lengths)
		setStrokeColor(color)

		// Draw
		addRect(rect)
		drawPath(using: drawingMode)

		// Cleanup
		restoreGState()
	}

	//------------------------------------------------------------------------------------------------------------------
	func drawDash(width :CGFloat, phase :CGFloat = 0.0, lengths :[CGFloat], in rect :CGRect, cornerRadius :CGFloat,
			color :CGColor, drawingMode :CGPathDrawingMode = .stroke) {
		// Setup
		let	minX = rect.minX
		let	midX = rect.midX
		let	maxX = rect.maxX

		let	minY = rect.minY
		let	midY = rect.midY
		let	maxY = rect.maxY

		// Setup Context
		saveGState()

		setLineWidth(width)
		setLineDash(phase: phase, lengths: lengths)
		setStrokeColor(color)

		// Draw
		move(to: CGPoint(x: minX, y: midY))
		addArc(tangent1End: CGPoint(x: minX, y: minY), tangent2End: CGPoint(x: midX, y: minY), radius: cornerRadius)
		addArc(tangent1End: CGPoint(x: maxX, y: minY), tangent2End: CGPoint(x: maxX, y: midY), radius: cornerRadius)
		addArc(tangent1End: CGPoint(x: maxX, y: maxY), tangent2End: CGPoint(x: midX, y: maxY), radius: cornerRadius)
		addArc(tangent1End: CGPoint(x: minX, y: maxY), tangent2End: CGPoint(x: minX, y: midY), radius: cornerRadius)
		closePath()
		drawPath(using: drawingMode)

		// Cleanup
		restoreGState()
	}
}
