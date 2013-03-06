//
//  CoreTextArcView.m
//  DMAComponents
//
//  Created by David Marioni on 27.12.11.
//  Copyright (c) 2011 David Marioni. All rights reserved.
//
#import "CoreTextArcView.h"
#import <AssertMacros.h>
#import <QuartzCore/QuartzCore.h>

#define ARCVIEW_DEBUG_MODE          NO

#define ARCVIEW_DEFAULT_FONT_NAME   @"Helvetica"
#define ARCVIEW_DEFAULT_FONT_SIZE   24.0
#define ARCVIEW_DEFAULT_RADIUS      -100.0
#define ARCVIEW_DEFAULT_ARC_SIZE    -80.0



@implementation CoreTextArcView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.font = [UIFont fontWithName:ARCVIEW_DEFAULT_FONT_NAME size:ARCVIEW_DEFAULT_FONT_SIZE];
        self.text = @"Curva Style Label";
        self.radius = ARCVIEW_DEFAULT_RADIUS;
        self.showsGlyphBounds = NO;
        self.showsLineMetrics = NO;
        self.dimsSubstitutedGlyphs = NO;
        self.color = [UIColor grayColor];
        self.arcSize = ARCVIEW_DEFAULT_ARC_SIZE;
        self.shiftH = self.shiftV = 0.0f;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame font:(UIFont *)font text:(NSString *)text radius:(float)radius arcSize:(float)arcSize color:(UIColor *)color{
    
    self = [super initWithFrame:frame];
    if (self) {
        self.font = font;
        self.text = text;
        self.radius = radius;
        self.showsGlyphBounds = NO;
        self.showsLineMetrics = NO;
        self.dimsSubstitutedGlyphs = NO;
        self.color = color;
        self.arcSize = arcSize;
        self.shiftH = self.shiftV = 0.0f;
    }
    return self;
}

typedef struct GlyphArcInfo {
    CGFloat         width;
    CGFloat         angle;  // in radians
} GlyphArcInfo;

static void PrepareGlyphArcInfo(CTLineRef line, CFIndex glyphCount, GlyphArcInfo *glyphArcInfo, CGFloat arcSizeRad)
{
    NSArray *runArray = (NSArray *)CTLineGetGlyphRuns(line);
	
		// Examine each run in the line, updating glyphOffset to track how far along the run is in terms of glyphCount.
    CFIndex glyphOffset = 0;
    for (id run in runArray) {
        CFIndex runGlyphCount = CTRunGetGlyphCount((CTRunRef)run);
		
			// Ask for the width of each glyph in turn.
        CFIndex runGlyphIndex = 0;
        for (; runGlyphIndex < runGlyphCount; runGlyphIndex++) {
            glyphArcInfo[runGlyphIndex + glyphOffset].width = CTRunGetTypographicBounds((CTRunRef)run, CFRangeMake(runGlyphIndex, 1), NULL, NULL, NULL);
        }
		
        glyphOffset += runGlyphCount;
    }
	
    double lineLength = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
	
    CGFloat prevHalfWidth = glyphArcInfo[0].width / 2.0;
    glyphArcInfo[0].angle = (prevHalfWidth / lineLength) * arcSizeRad;
	
		// Divide the arc into slices such that each one covers the distance from one glyph's center to the next.
    CFIndex lineGlyphIndex = 1;
    for (; lineGlyphIndex < glyphCount; lineGlyphIndex++) {
        CGFloat halfWidth = glyphArcInfo[lineGlyphIndex].width / 2.0;
        CGFloat prevCenterToCenter = prevHalfWidth + halfWidth;
		
        glyphArcInfo[lineGlyphIndex].angle = (prevCenterToCenter / lineLength) * arcSizeRad;
		
        prevHalfWidth = halfWidth;
    }
}


	// ensure that redraw occurs.
-(void)setText:(NSString *)text{
    [_string release];
    _string = [text retain];
	
    [self setNeedsDisplay];
}

	//set arc size in degrees (180 = half circle)
-(void)setArcSize:(CGFloat)degrees{
    _arcSize = degrees * M_PI/180.0;
}

	//get arc size in degrees
-(CGFloat)arcSize{
    return _arcSize * 180.0/M_PI;
}

- (void)drawRect:(CGRect)rect {
		// Don't draw if we don't have a font or string
    if (self.font == NULL || self.text == NULL) 
        return;
	
		// Initialize the text matrix to a known value
    CGContextRef context = UIGraphicsGetCurrentContext();
		//Reset the transformation
		//Doing this means you have to reset the contentScaleFactor to 1.0
    CGAffineTransform t0 = CGContextGetCTM(context);
	
	
    CGFloat xScaleFactor = t0.a > 0 ? t0.a : -t0.a;
    CGFloat yScaleFactor = t0.d > 0 ? t0.d : -t0.d;
    t0 = CGAffineTransformInvert(t0);
    if (xScaleFactor != 1.0 || yScaleFactor != 1.0)
        t0 = CGAffineTransformScale(t0, xScaleFactor, yScaleFactor);
	
    CGContextConcatCTM(context, t0);
	
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	
    if(ARCVIEW_DEBUG_MODE){
			// Draw a black background (debug)
        CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
        CGContextFillRect(context, self.layer.bounds);
    }
	
    NSAttributedString *attStr = self.attributedString;
    CFAttributedStringRef asr = (CFAttributedStringRef)attStr;
    CTLineRef line = CTLineCreateWithAttributedString(asr);
    assert(line != NULL);
	
    CFIndex glyphCount = CTLineGetGlyphCount(line);
    if (glyphCount == 0) {
        CFRelease(line);
        return;
    }
	
    GlyphArcInfo *  glyphArcInfo = (GlyphArcInfo*)calloc(glyphCount, sizeof(GlyphArcInfo));
    PrepareGlyphArcInfo(line, glyphCount, glyphArcInfo, _arcSize);
	
		// Move the origin from the lower left of the view nearer to its center.
    CGContextSaveGState(context);
	
    CGContextTranslateCTM(context, CGRectGetMidX(rect)+_shiftH, CGRectGetMidY(rect)+_shiftV - self.radius / 2.0);
	
    if(ARCVIEW_DEBUG_MODE){
			// Stroke the arc in red for verification.
        CGContextBeginPath(context);
        CGContextAddArc(context, 0.0, 0.0, self.radius, M_PI_2+_arcSize/2.0, M_PI_2-_arcSize/2.0, 1);
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextStrokePath(context);
    }
	
		// Rotate the context 90 degrees counterclockwise (per 180 degrees)
    CGContextRotateCTM(context, _arcSize/2.0);
	
		// Now for the actual drawing. The angle offset for each glyph relative to the previous glyph has already been calculated; with that information in hand, draw those glyphs overstruck and centered over one another, making sure to rotate the context after each glyph so the glyphs are spread along a semicircular path.
	
    CGPoint textPosition = CGPointMake(0.0, self.radius);
    CGContextSetTextPosition(context, textPosition.x, textPosition.y);
	
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    CFIndex runCount = CFArrayGetCount(runArray);
	
    CFIndex glyphOffset = 0;
    CFIndex runIndex = 0;
    for (; runIndex < runCount; runIndex++) {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, runIndex);
        CFIndex runGlyphCount = CTRunGetGlyphCount(run);
        Boolean drawSubstitutedGlyphsManually = false;
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
		
			// Determine if we need to draw substituted glyphs manually. Do so if the runFont is not the same as the overall font.
        if (self.dimsSubstitutedGlyphs && ![self.font isEqual:(UIFont *)runFont]) {
            drawSubstitutedGlyphsManually = true;
        }
		
        CFIndex runGlyphIndex = 0;
        for (; runGlyphIndex < runGlyphCount; runGlyphIndex++) {
            CFRange glyphRange = CFRangeMake(runGlyphIndex, 1);
            CGContextRotateCTM(context, -(glyphArcInfo[runGlyphIndex + glyphOffset].angle));
			
				// Center this glyph by moving left by half its width.
            CGFloat glyphWidth = glyphArcInfo[runGlyphIndex + glyphOffset].width;
            CGFloat halfGlyphWidth = glyphWidth / 2.0;
            CGPoint positionForThisGlyph = CGPointMake(textPosition.x - halfGlyphWidth, textPosition.y);
			
				// Glyphs are positioned relative to the text position for the line, so offset text position leftwards by this glyph's width in preparation for the next glyph.
            textPosition.x -= glyphWidth;
			
            CGAffineTransform textMatrix = CTRunGetTextMatrix(run);
            textMatrix.tx = positionForThisGlyph.x;
            textMatrix.ty = positionForThisGlyph.y;
            CGContextSetTextMatrix(context, textMatrix);
			
            if (!drawSubstitutedGlyphsManually) {
                CTRunDraw(run, context, glyphRange);
            } 
            else {
					// We need to draw the glyphs manually in this case because we are effectively applying a graphics operation by setting the context fill color. Normally we would use kCTForegroundColorAttributeName, but this does not apply as we don't know the ranges for the colors in advance, and we wanted demonstrate how to manually draw.
                CGFontRef cgFont = CTFontCopyGraphicsFont(runFont, NULL);
                CGGlyph glyph;
                CGPoint position;
				
                CTRunGetGlyphs(run, glyphRange, &glyph);
                CTRunGetPositions(run, glyphRange, &position);
				
                CGContextSetFont(context, cgFont);
                CGContextSetFontSize(context, CTFontGetSize(runFont));
                CGContextSetRGBFillColor(context, 0.25, 0.25, 0.25, 0.5);
                CGContextShowGlyphsAtPositions(context, &glyph, &position, 1);
				
                CFRelease(cgFont);
            }
			
				// Draw the glyph bounds 
            if ((self.showsGlyphBounds) != 0) {
                CGRect glyphBounds = CTRunGetImageBounds(run, context, glyphRange);
				
                CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 1.0);
                CGContextStrokeRect(context, glyphBounds);
            }
				// Draw the bounding boxes defined by the line metrics
            if ((self.showsLineMetrics) != 0) {
                CGRect lineMetrics;
                CGFloat ascent, descent;
				
                CTRunGetTypographicBounds(run, glyphRange, &ascent, &descent, NULL);
				
					// The glyph is centered around the y-axis
                lineMetrics.origin.x = -halfGlyphWidth;
                lineMetrics.origin.y = positionForThisGlyph.y - descent;
                lineMetrics.size.width = glyphWidth; 
                lineMetrics.size.height = ascent + descent;
				
                CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
                CGContextStrokeRect(context, lineMetrics);
            }
        }
		
        glyphOffset += runGlyphCount;
    }
	
	CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetAlpha(context,0.0);
    CGContextFillRect(context, rect);
	
    CGContextRestoreGState(context);
	
    free(glyphArcInfo);
    CFRelease(line);    
	
	
	
}

@synthesize font = _font;
@synthesize text = _string;
@synthesize radius = _radius;
@synthesize color = _color;
@synthesize arcSize = _arcSize;
@synthesize shiftH = _shiftH;
@synthesize shiftV = _shiftV;

@dynamic attributedString;
- (NSAttributedString *)attributedString {
		// Create an attributed string with the current font and string.
    assert(self.font != nil);
    assert(self.text != nil);
	
		// Create our attributes...
	
		// font
    CTFontRef fontRef = CTFontCreateWithName((CFStringRef)self.font.fontName, self.font.pointSize, NULL);
	
		// color
    CGColorRef colorRef = self.color.CGColor;
	
		// pack it into attributes dictionary
	
    NSDictionary *attributesDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)fontRef, (id)kCTFontAttributeName,
                                    colorRef, (id)kCTForegroundColorAttributeName,
                                    nil];
    assert(attributesDict != nil);
	
	
		// Create the attributed string
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:self.text attributes:attributesDict];
	
    return [attrString autorelease];
}

@dynamic showsGlyphBounds;
- (BOOL)showsGlyphBounds {
    return _flags.showsGlyphBounds;
}

- (void)setShowsGlyphBounds:(BOOL)show {
    _flags.showsGlyphBounds = show ? 1 : 0;
}

@dynamic showsLineMetrics;
- (BOOL)showsLineMetrics {
    return _flags.showsLineMetrics;
}

- (void)setShowsLineMetrics:(BOOL)show {
    _flags.showsLineMetrics = show ? 1 : 0;
}

@dynamic dimsSubstitutedGlyphs;
- (BOOL)dimsSubstitutedGlyphs {
    return _flags.dimsSubstitutedGlyphs;
}

- (void)setDimsSubstitutedGlyphs:(BOOL)dim {
    _flags.dimsSubstitutedGlyphs = dim ? 1 : 0;
}

@end