#import "CustomCropManager.h"
#import <React/RCTLog.h>

@implementation CustomCropManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(crop:(NSDictionary *)points imageUri:(NSString *)imageUri verticalScale:(float)verticalScale contrast:(float)contrast brightness:(float)brightness callback:(RCTResponseSenderBlock)callback)
{
    NSString *parsedImageUri = [imageUri stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSURL *fileURL = [NSURL fileURLWithPath:parsedImageUri];
    CIImage *ciImage = [CIImage imageWithContentsOfURL:fileURL];
    
    CGPoint newLeft = CGPointMake([points[@"topLeft"][@"x"] floatValue], [points[@"topLeft"][@"y"] floatValue]);
    CGPoint newRight = CGPointMake([points[@"topRight"][@"x"] floatValue], [points[@"topRight"][@"y"] floatValue]);
    CGPoint newBottomLeft = CGPointMake([points[@"bottomLeft"][@"x"] floatValue], [points[@"bottomLeft"][@"y"] floatValue]);
    CGPoint newBottomRight = CGPointMake([points[@"bottomRight"][@"x"] floatValue], [points[@"bottomRight"][@"y"] floatValue]);
    
    newLeft = [self cartesianForPoint:newLeft height:[points[@"height"] floatValue] ];
    newRight = [self cartesianForPoint:newRight height:[points[@"height"] floatValue] ];
    newBottomLeft = [self cartesianForPoint:newBottomLeft height:[points[@"height"] floatValue] ];
    newBottomRight = [self cartesianForPoint:newBottomRight height:[points[@"height"] floatValue] ];
    
    
    
    NSMutableDictionary *rectangleCoordinates = [[NSMutableDictionary alloc] init];
    
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:newLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:newRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:newBottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:newBottomRight];
    
    ciImage = [ciImage imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
    
    // custom code
    
    contrast = contrast * 5;
    
    /*
    CIFilter *colorControlsFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorControlsFilter setDefaults];
    [colorControlsFilter setValue:ciImage forKey:@"inputImage"];
    [colorControlsFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputSaturation"];
    [colorControlsFilter setValue:[NSNumber numberWithFloat:(brightness / 100)] forKey:@"inputBrightness"];
    [colorControlsFilter setValue:[NSNumber numberWithFloat:contrast] forKey:@"inputContrast"];
    CIImage *outputImage = [colorControlsFilter valueForKey:@"outputImage"];
    */
    
    CIFilter *filter = [CIFilter filterWithName:@"CIExposureAdjust"];
    [filter setValue:ciImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:contrast] forKey:@"inputEV"];
    ciImage = filter.outputImage;
    
    CIFilter *filter2 = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    [filter2 setValue:ciImage forKey:@"inputImage"];
    [filter2 setValue:@1.0 forKey:@"inputScale"];
    [filter2 setValue:[NSNumber numberWithFloat:verticalScale] forKey:@"inputAspectRatio"];
    ciImage = filter2.outputImage;
    
    //
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    UIImage *image = [UIImage imageWithCGImage:cgimage];
    
    NSData *imageToEncode = UIImageJPEGRepresentation(image, 0.8);
    callback(@[[NSNull null], @{@"image": [imageToEncode base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]}]);
}

- (CGPoint)cartesianForPoint:(CGPoint)point height:(float)height {
    return CGPointMake(point.x, height - point.y);
}

@end
