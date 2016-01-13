import Cocoa

// NSColor extensions that are useful for an application like this.
public extension NSColor {
	
	// Parse an NSColor from a hex string.
	// from: https://github.com/thii/SwiftHEXColors
	public convenience init(var hex: String, alpha: Float = 1.0) {
		
		// Strip leading # prefix from hex digits.
		if hex.hasPrefix("#") {
			hex = hex.substringFromIndex(hex.startIndex.advancedBy(1))
		}
		
		// Ensure it's actually a color string, otherwise bail.
		if hex.rangeOfString("(^[0-9A-Fa-f]{6}$)|(^[0-9A-Fa-f]{3}$)", options: .RegularExpressionSearch) == nil {
			self.init(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
			return
		}
		
		// If it's a short-form (3 character) color, expand it.
		if hex.characters.count == 3 {
			let r = hex.substringToIndex(hex.startIndex.advancedBy(1))
			let g = hex.substringWithRange(Range<String.Index>(start: hex.startIndex.advancedBy(1), end: hex.startIndex.advancedBy(2)))
			let b = hex.substringFromIndex(hex.startIndex.advancedBy(2))
			hex = r + r + g + g + b + b
		}
		
		// Split the color components out.
		let rh = hex.substringToIndex(hex.startIndex.advancedBy(2))
		let gh = hex.substringWithRange(Range<String.Index>(start: hex.startIndex.advancedBy(2), end: hex.startIndex.advancedBy(4)))
		let bh = hex.substringWithRange(Range<String.Index>(start: hex.startIndex.advancedBy(4), end: hex.startIndex.advancedBy(6)))
		
		// Scan the color components into integers.
		var r: UInt32 = 0, g: UInt32 = 0, b: UInt32 = 0
		NSScanner(string: rh).scanHexInt(&r)
		NSScanner(string: gh).scanHexInt(&g)
		NSScanner(string: bh).scanHexInt(&b)
		
		// Finally initialize with the calibrated color components.
		self.init(calibratedRed: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0,
				  blue: CGFloat(b) / 255.0, alpha: CGFloat(alpha))
	}
	
	// 
	// Material Design colors follow:
	//
	
	public class func materialRedColor() -> NSColor {
		return NSColor(hex: "#F44336")
	}
	
	public class func materialPinkColor() -> NSColor {
		return NSColor(hex: "#E91E63")
	}
	
	public class func materialPurpleColor() -> NSColor {
		return NSColor(hex: "#9C27B0")
	}
	
	public class func materialDeepPurpleColor() -> NSColor {
		return NSColor(hex: "#673AB7")
	}
	
	public class func materialIndigoColor() -> NSColor {
		return NSColor(hex: "#3F51B5")
	}
	
	public class func materialBlueColor() -> NSColor {
		return NSColor(hex: "#2196F3")
	}
	
	public class func materialLightBlueColor() -> NSColor {
		return NSColor(hex: "#03A9F4")
	}
	
	public class func materialCyanColor() -> NSColor {
		return NSColor(hex: "#00BCD4")
	}
	
	public class func materialTealColor() -> NSColor {
		return NSColor(hex: "#009688")
	}
	
	public class func materialGreenColor() -> NSColor {
		return NSColor(hex: "#4CAF50")
	}
	
	public class func materialLightGreenColor() -> NSColor {
		return NSColor(hex: "#8BC34A")
	}
	
	public class func materialLimeColor() -> NSColor {
		return NSColor(hex: "#CDDC39")
	}
	
	public class func materialYellowColor() -> NSColor {
		return NSColor(hex: "#FFEB3B")
	}
	
	public class func materialAmberColor() -> NSColor {
		return NSColor(hex: "#FFC107")
	}
	
	public class func materialOrangeColor() -> NSColor {
		return NSColor(hex: "#FF9800")
	}
	
	public class func materialDeepOrangeColor() -> NSColor {
		return NSColor(hex: "#FF5722")
	}
	
	public class func materialBrownColor() -> NSColor {
		return NSColor(hex: "#795548")
	}
	
	public class func materialGreyColor() -> NSColor {
		return NSColor(hex: "#9E9E9E")
	}
	
	public class func materialBlueGreyColor() -> NSColor {
		return NSColor(hex: "#607D8B")
	}
}