//
//  Cordova
//
//

#import "MapKit.h"
#import "CDVAnnotation.h"
#import "AsyncImageView.h"

#import "JSONKit.h"
#import "DDAnnotation.h"
#import "DDAnnotationView.h"

@implementation MapKitView

@synthesize dragCallback;
@synthesize buttonCallback;
@synthesize childView;
@synthesize mapView;
//@synthesize imageButton;


-(CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    self = (MapKitView*)[super initWithWebView:theWebView];
    return self;
}

/**
 * Create a native map view
 */
- (void)createView
{
	self.childView = [[UIView alloc] init];
    self.mapView = [[MKMapView alloc] init];
    [self.mapView sizeToFit];
    self.mapView.delegate = self;
    self.mapView.multipleTouchEnabled   = YES;
    self.mapView.autoresizesSubviews    = YES;
    self.mapView.userInteractionEnabled = YES;
	self.mapView.showsUserLocation = YES;
	self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.childView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	//self.imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	[self.childView addSubview:self.mapView];
	//[self.childView addSubview:self.imageButton];
    
	[ [ [ super viewController ] view ] addSubview:self.childView];  
}


- (void)mapView:(MKMapView *)theMapView regionDidChangeAnimated: (BOOL)animated 
{ 
    float currentLat = theMapView.region.center.latitude; 
    float currentLon = theMapView.region.center.longitude; 
    float latitudeDelta = theMapView.region.span.latitudeDelta; 
    float longitudeDelta = theMapView.region.span.longitudeDelta; 
    
    NSString* jsString = nil;
	jsString = [[NSString alloc] initWithFormat:@"geo.onMapMove(\'%f','%f','%f','%f\');", currentLat,currentLon,latitudeDelta,longitudeDelta];
	[self.webView stringByEvaluatingJavaScriptFromString:jsString];
	[jsString autorelease];
}

- (void)destroyMap:(CDVInvokedUrlCommand*)command
{
	if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];
        
		mapView = nil;
	}
    if(self.childView)
	{
		[ self.childView removeFromSuperview];
		self.childView = nil;
	}
    self.buttonCallback = nil;
}

- (void)clearMapPins:(CDVInvokedUrlCommand*)command;
{
    [self.mapView removeAnnotations:self.mapView.annotations];
}

- (void)addMapPins:(CDVInvokedUrlCommand*)command;
{
    NSArray *pins = [[command.arguments objectAtIndex:0] objectFromJSONString];
    
    for (int y = 0; y < pins.count; y++) 
	{
		NSDictionary *pinData = [pins objectAtIndex:y];
		CLLocationCoordinate2D pinCoord = { [[pinData objectForKey:@"lat"] floatValue] , [[pinData objectForKey:@"lon"] floatValue] };
		NSString *title=[[pinData valueForKey:@"title"] description];
		NSString *subTitle=[[pinData valueForKey:@"subTitle"] description];
        NSString *formattedSubtitle = [[pinData valueForKey:@"formattedSubtitle"] description]; 
		NSString *imageURL=[[pinData valueForKey:@"imageURL"] description];
		NSString *pinColor=[[pinData valueForKey:@"pinColor"] description];
		NSInteger index=[[pinData valueForKey:@"index"] integerValue];
        BOOL selected = [[pinData valueForKey:@"selected"] boolValue];
        BOOL dragable = [[pinData valueForKey:@"dragable"] boolValue];
                       
        if(dragable){
            DDAnnotation * annotation = [[DDAnnotation alloc] initWithCoordinate:pinCoord addressDictionary:nil];
            annotation.index = index;
            annotation.title = title;
            annotation.formattedSubtitle = formattedSubtitle;
                        
            if(formattedSubtitle)
                annotation.subtitle = [NSString stringWithFormat:formattedSubtitle, pinCoord.latitude, pinCoord.longitude];	
            else
                annotation.subtitle = subTitle;
                                       
            annotation.imageURL = imageURL;
            annotation.pinColor = pinColor;
            annotation.selected = selected;
            [self.mapView addAnnotation:annotation];
        }else{
            CDVAnnotation *annotation = [[CDVAnnotation alloc] initWithCoordinate:pinCoord index:index title:title subTitle:subTitle imageURL:imageURL];
            annotation.pinColor=pinColor;
            annotation.selected = selected;
            [self.mapView addAnnotation:annotation];
            [annotation release];
        }
    }    
}

/**
 * Set annotations and mapview settings
 */
- (void)setMapData:(CDVInvokedUrlCommand*)command;
{	
    if (!self.mapView) 
	{
		[self createView];
	}
	
	// defaults
    CGFloat height = 480.0f;
    CGFloat offsetTop = 0.0f;
    
	if ([[command.arguments objectAtIndex:0] objectForKey:@"height"])
	{
		height=[[[command.arguments objectAtIndex:0] objectForKey:@"height"] floatValue];
	}
    if ([[command.arguments objectAtIndex:0] objectForKey:@"offsetTop"])
	{
		offsetTop=[[[command.arguments objectAtIndex:0] objectForKey:@"offsetTop"] floatValue];
	}
	if ([[command.arguments objectAtIndex:0] objectForKey:@"buttonCallback"])
	{
		self.buttonCallback=[[[command.arguments objectAtIndex:0] objectForKey:@"buttonCallback"] description];
	}
    if([[command.arguments objectAtIndex:0] objectForKey:@"dragCallback"])
    {
        self.dragCallback=[[[command.arguments objectAtIndex:0] objectForKey:@"dragCallback"] description];
    }
	
	CLLocationCoordinate2D centerCoord = { [[[command.arguments objectAtIndex:0] objectForKey:@"lat"] floatValue] , [[[command.arguments objectAtIndex:0] objectForKey:@"lon"] floatValue] };
	CLLocationDistance diameter = [[[command.arguments objectAtIndex:0] objectForKey:@"diameter"] floatValue];
	
	
	CGRect webViewBounds = self.webView.bounds;
    CGRect rect;
    rect = [[UIApplication sharedApplication] statusBarFrame];
    
    if(rect.size.height == 40){
        height = height -20;
    }
    
	CGRect mapBounds;
    mapBounds = CGRectMake(
                           webViewBounds.origin.x,
                           webViewBounds.origin.y + (offsetTop / 2),
                           webViewBounds.size.width,
                           webViewBounds.origin.y + height
                           );
    
	[self.childView setFrame:mapBounds];
	[self.mapView setFrame:mapBounds];
	
	MKCoordinateRegion region=[ self.mapView regionThatFits: MKCoordinateRegionMakeWithDistance(centerCoord, 
                                                                                                diameter*(height / webViewBounds.size.width), 
                                                                                                diameter*(height / webViewBounds.size.width))];
	[self.mapView setRegion:region animated:YES];
	
}

- (void) closeButton:(id)button
{
	[ self hideMap:NULL];
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback,-1];
	[self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)showMap:(CDVInvokedUrlCommand*)command
{
	if (!self.mapView) 
	{
		[self createView];
	}
	self.childView.hidden = NO;
	self.mapView.showsUserLocation = YES;
}


- (void)hideMap:(CDVInvokedUrlCommand*)command
{
    if (!self.mapView || self.childView.hidden==YES) 
	{
		return;
	}
	// disable location services, if we no longer need it.
	self.mapView.showsUserLocation = NO;
	self.childView.hidden = YES;
}

#pragma mark -
#pragma mark DDAnnotationCoordinateDidChangeNotification

// NOTE: DDAnnotationCoordinateDidChangeNotification won't fire in iOS 4, use -mapView:annotationView:didChangeDragState:fromOldState: instead.
- (void)coordinateChanged_:(NSNotification *)notification {
	
	DDAnnotation *annotation = notification.object;
	
    if(annotation.formattedSubtitle){
        annotation.subtitle = [NSString	stringWithFormat:annotation.formattedSubtitle, annotation.coordinate.latitude, annotation.coordinate.longitude];            
    }
    
    NSString* jsString = [NSString stringWithFormat:@"%@(\"%i, %f, %f\");", self.dragCallback, annotation.index, 
                          annotation.coordinate.latitude, annotation.coordinate.longitude];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	
	if (oldState == MKAnnotationViewDragStateDragging) {
		DDAnnotation *annotation = (DDAnnotation *)annotationView.annotation;
        
        if(annotation.formattedSubtitle){
            annotation.subtitle = [NSString	stringWithFormat:annotation.formattedSubtitle, annotation.coordinate.latitude, annotation.coordinate.longitude];            
        }
			
        NSString* jsString = [NSString stringWithFormat:@"%@(%i, %f, %f);", self.dragCallback, annotation.index, 
                              annotation.coordinate.latitude, annotation.coordinate.longitude];
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
	}
}



- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>) annotation {
    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;		
	}
    
    if([annotation class] == DDAnnotation.class){
        static NSString * const kPinAnnotationIdentifier = @"PinIdentifier";
        MKAnnotationView *draggablePinView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationIdentifier];
        
        if (draggablePinView) {
            
            draggablePinView.annotation = annotation;
        } else {
            // Use class method to create DDAnnotationView (on iOS 3) or built-in draggble MKPinAnnotationView (on iOS 4).
            draggablePinView = [DDAnnotationView annotationViewWithAnnotation:annotation reuseIdentifier:kPinAnnotationIdentifier mapView:self.mapView];
            
            if ([draggablePinView isKindOfClass:[DDAnnotationView class]]) {
                // draggablePinView is DDAnnotationView on iOS 3.
            } else {
                // draggablePinView instance will be built-in draggable MKPinAnnotationView when running on iOS 4.
            }
        }		
        
        return draggablePinView;
        
    }
    
    if([annotation class] == CDVAnnotation.class){
        
        CDVAnnotation *phAnnotation=(CDVAnnotation *) annotation;
        NSString *identifier=[NSString stringWithFormat:@"INDEX[%i]", phAnnotation.index];
        
        MKPinAnnotationView *annView = (MKPinAnnotationView *)[theMapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (annView!=nil) return annView;
        
        annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        
        annView.animatesDrop=YES;
        annView.canShowCallout = YES;
        if ([phAnnotation.pinColor isEqualToString:@"green"])
            annView.pinColor = MKPinAnnotationColorGreen;
        else if ([phAnnotation.pinColor isEqualToString:@"purple"])
            annView.pinColor = MKPinAnnotationColorPurple;
        else
            annView.pinColor = MKPinAnnotationColorRed;
        
        AsyncImageView* asyncImage = [[[AsyncImageView alloc] initWithFrame:CGRectMake(0,0, 50, 32)] autorelease];
        asyncImage.tag = 999;
        if (phAnnotation.imageURL)
        {
            NSURL *url = [[NSURL alloc] initWithString:phAnnotation.imageURL]; 
            if ( [ [url scheme] isEqualToString:@"http"] || [ [url scheme] isEqualToString:@"https"] )  { 
                [asyncImage loadImageFromURL:url]; 
            } 
            else { 
                [asyncImage loadImageFromPath:phAnnotation.imageURL]; 
            } 
        	
            [ url release ];
        } 
        else 
        {
            [asyncImage loadDefaultImage];
        }
        
        annView.leftCalloutAccessoryView = asyncImage;
        
        
        if (self.buttonCallback && phAnnotation.index!=-1)
        {
            
            UIButton *myDetailButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            myDetailButton.frame = CGRectMake(0, 0, 23, 23);
            myDetailButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            myDetailButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            myDetailButton.tag=phAnnotation.index;
            annView.rightCalloutAccessoryView = myDetailButton;
            [ myDetailButton addTarget:self action:@selector(checkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            
        }
        
        if(phAnnotation.selected)
        {
            [self performSelector:@selector(openAnnotation:) withObject:phAnnotation afterDelay:1.0];
        }
        
        return [annView autorelease];
    }
    
    return nil;
}

-(void)openAnnotation:(id <MKAnnotation>) annotation
{
	[ self.mapView selectAnnotation:annotation animated:YES];  
	
}

- (void) checkButtonTapped:(id)button 
{
	UIButton *tmpButton = button;
	NSString* jsString = [NSString stringWithFormat:@"%@(\"%i\");", self.buttonCallback, tmpButton.tag];
	[self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

// pad our map by 10% around the farthest annotations
#define MAP_PADDING 1.1

// we'll make sure that our minimum vertical span is about a kilometer
// there are ~111km to a degree of latitude. regionThatFits will take care of
// longitude, which is more complicated, anyway. 
#define MINIMUM_VISIBLE_LATITUDE 0.01
- (void) zoomToPins: (CDVInvokedUrlCommand*)command;
{
    CLLocationDegrees minLatitude = 90.0;
    CLLocationDegrees maxLatitude = -90.0;
    CLLocationDegrees minLongitude = 180.0;
    CLLocationDegrees maxLongitude = -180.0;
    
    for (int i =0; i < [self.mapView.annotations count]; i++) 
    {
        if ([[self.mapView.annotations objectAtIndex:i] isKindOfClass:[CDVAnnotation class]] )
        {
            CDVAnnotation *p =(CDVAnnotation*)[self.mapView.annotations objectAtIndex:i];
            if (p.coordinate.latitude < minLatitude)
                minLatitude = p.coordinate.latitude;
            if (p.coordinate.latitude > maxLatitude)
                maxLatitude = p.coordinate.latitude;
            if (p.coordinate.longitude < minLongitude)
                minLongitude = p.coordinate.longitude;
            if (p.coordinate.longitude > maxLongitude)
                maxLongitude = p.coordinate.longitude;
        }
        
        if ([[self.mapView.annotations objectAtIndex:i] isKindOfClass:[DDAnnotation class]] )
        {
            DDAnnotation *p =(DDAnnotation*)[self.mapView.annotations objectAtIndex:i];
            if (p.coordinate.latitude < minLatitude)
                minLatitude = p.coordinate.latitude;
            if (p.coordinate.latitude > maxLatitude)
                maxLatitude = p.coordinate.latitude;
            if (p.coordinate.longitude < minLongitude)
                minLongitude = p.coordinate.longitude;
            if (p.coordinate.longitude > maxLongitude)
                maxLongitude = p.coordinate.longitude;
        }

        
        
    }
        
    MKCoordinateRegion region;
    region.center.latitude = (minLatitude + maxLatitude) / 2;
    region.center.longitude = (minLongitude + maxLongitude) / 2;
    
    region.span.latitudeDelta = (maxLatitude - minLatitude) * MAP_PADDING;
    
    region.span.latitudeDelta = (region.span.latitudeDelta < MINIMUM_VISIBLE_LATITUDE) ? MINIMUM_VISIBLE_LATITUDE : region.span.latitudeDelta;
    
    region.span.longitudeDelta = (maxLongitude - minLongitude) * MAP_PADDING;
    
    MKCoordinateRegion scaledRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:scaledRegion animated:YES];
}

- (void)dealloc
{
    if (self.mapView)
	{
		[ self.mapView removeAnnotations:mapView.annotations];
		[ self.mapView removeFromSuperview];
        self.mapView = nil;
	}
	if(childView)
	{
		[ self.childView removeFromSuperview];
        self.childView = nil;
	}
    self.buttonCallback = nil;
    self.dragCallback = nil;
    [super dealloc];
}



@end
