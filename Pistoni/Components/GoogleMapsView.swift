//
//  GoogleMapsView.swift
//  SNI Rentals
//
//  Created by Assistant on 20/01/25.
//

import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Google Maps SwiftUI Wrapper
struct GoogleMapsView: UIViewRepresentable {
    @Binding var mapPosition: GMSCameraPosition
    @State private var mapView: GMSMapView?
    
    // Check if we're in preview mode
    private var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // Camera position for Google Maps
    private var cameraPosition: GMSCameraPosition {
        return mapPosition
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        // For preview mode, return a simplified map view to improve loading time
        if isPreview {
            let mapView = GMSMapView()
            mapView.camera = cameraPosition
            
            // Disable heavy features in preview
            mapView.isMyLocationEnabled = false
            mapView.settings.myLocationButton = false
            mapView.settings.compassButton = false
            
            // Add a simple overlay to indicate this is a preview
            let marker = GMSMarker()
            marker.position = mapView.camera.target
            marker.title = "Preview Mode"
            marker.snippet = "Map loading optimized for preview"
            marker.map = mapView
            
            return mapView
        }
        
        // Normal implementation for actual app
        let mapView = GMSMapView()
        
        // Configure map settings
        mapView.camera = cameraPosition
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.settings.compassButton = true
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = true
        
        // Set map style to match the realistic elevation style from MapKit
        mapView.mapType = .normal
        
        // Apply custom blue-toned styling
        if let styleURL = Bundle.main.url(forResource: "map_style", withExtension: "json") {
            do {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } catch {
                print("Failed to load map style: \(error)")
            }
        } else {
            // Fallback: Apply inline blue-toned style
            let blueMapStyle = GoogleMapsConfiguration.getBlueMapStyle()
            do {
                mapView.mapStyle = try GMSMapStyle(jsonString: blueMapStyle)
            } catch {
                print("Failed to apply blue map style: \(error)")
            }
        }
        
        // Set delegate for camera changes
        mapView.delegate = context.coordinator
        
        self.mapView = mapView
        return mapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        // Update camera position when binding changes
        let newCameraPosition = cameraPosition
        if uiView.camera.target.latitude != newCameraPosition.target.latitude ||
           uiView.camera.target.longitude != newCameraPosition.target.longitude {
            uiView.animate(to: newCameraPosition)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
            // Update the binding when camera position changes
            parent.mapPosition = position
        }
    }
}

// MARK: - Google Maps Configuration
struct GoogleMapsConfiguration {
    static func configure() {
        // Configure Google Maps with API key
        let apiKey = "AIzaSyBWiQw1KnUfCMbGsbRJCpRF-DXzBaxunek"
        GMSServices.provideAPIKey(apiKey)
    }
    
    static func getBlueMapStyle() -> String {
        return """
         [
          {
            "featureType": "all",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#e8f4fd"
              }
            ]
          },
          {
            "featureType": "all",
            "elementType": "labels.text.fill",
            "stylers": [
              {
                "color": "#4a90e2"
              }
            ]
          },
          {
            "featureType": "all",
            "elementType": "labels.text.stroke",
            "stylers": [
              {
                "color": "#ffffff"
              },
              {
                "weight": 2
              }
            ]
          },
          {
            "featureType": "road",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#7bb3f0"
              }
            ]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#5a9bd4"
              }
            ]
          },
          {
            "featureType": "road.arterial",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#6bb6ed"
              }
            ]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#a2d2ff"
              }
            ]
          },
          {
            "featureType": "landscape",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#f0f8ff"
              }
            ]
          },
          {
            "featureType": "poi",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#ddeeff"
              }
            ]
          },
          {
            "featureType": "poi.park",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#c8e6c9"
              }
            ]
          },
          {
            "featureType": "transit",
            "elementType": "geometry",
            "stylers": [
              {
                "color": "#81c784"
              }
            ]
          }
         ]
         """
     }
}

// MARK: - Preview
#if DEBUG
struct GoogleMapsView_Previews: PreviewProvider {
    @State static var mapPosition = GMSCameraPosition.camera(withLatitude: -6.7924, longitude: 39.2083, zoom: 15.0)
    
    static var previews: some View {
        GoogleMapsView(mapPosition: $mapPosition)
            .onAppear {
                // Skip Google Maps configuration in preview to avoid crashes
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                    GoogleMapsConfiguration.configure()
                }
            }
    }
}
#endif