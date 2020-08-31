//
//  SwiftUIView.swift
//  Airflow
//
//  Created by Sanchitha Dinesh on 8/29/20.
//  Copyright © 2020 Sanchitha Dinesh. All rights reserved.
//
import SwiftUI
import MapKit

struct HomeView: View {
    
    @ObservedObject var airQuality = AirQuality()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        TabView {
            
            AQMapView(checkpoints: airQuality.aqiData)
                //            VStack{
                //
                //                Text("Air Quality Data")
                //                    .font(.headline)
                //                    .padding()
                //            }
                .tabItem {
                    VStack{
                        Image(systemName: "mappin")
                        Text("Location")
                    }
            }.tag(1)
        }.onReceive(self.timer) { _ in
            addNotification()
        }
    }
}
class MapViewCoordinator: NSObject, MKMapViewDelegate {
    
    var mapViewController: AQMapView
    
    init(_ control: AQMapView) {
        self.mapViewController = control
    }
    
    func mapView(_ mapView: MKMapView, viewFor
        annotation: MKAnnotation) -> MKAnnotationView?{
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "anno")
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "anno")
            annotationView?.canShowCallout = true
        }
        
        if let annotaion = annotationView as? MKAnnotationView {
            annotationView = annotaion
        }
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if let annotate = annotation as? AQAnnotations {
            subtitleLabel.text = "Current AQI is " + String(annotate.aqi) ?? "NA"
        }
        annotationView?.detailCalloutAccessoryView = subtitleLabel
        
        return annotationView
    }
}

struct AQMapView: UIViewRepresentable {
    var checkpoints: [AQAnnotations]
    var locationManager = CLLocationManager()
    func setupManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
    }
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: UIScreen.main.bounds)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = context.coordinator
        return mapView
    }
    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
        uiView.addAnnotations(checkpoints)
        
        if let first = checkpoints.first{
            uiView.selectAnnotation(first, animated: true)
            
        }
    }
    
}

func addNotification() {
    let center = UNUserNotificationCenter.current()

    let addRequest = {
        let content = UNMutableNotificationContent()
        content.title = "The current air quality is Moderate. Please stay indoors"
        content.sound = UNNotificationSound.default

      
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // add our notification request
        UNUserNotificationCenter.current().add(request)
        
        center.add(request)
        
    }

    center.getNotificationSettings { settings in
        if settings.authorizationStatus == .authorized {
            addRequest()
        } else {
            center.requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                if success {
                    addRequest()
                } else {
                    print("D'oh")
                }
            }
        }
    }

}

