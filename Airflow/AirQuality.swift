//
//  AirQuality.swift
//  Airflow
//
//  Created by Sanchitha Dinesh on 8/29/20.
//  Copyright © 2020 Sanchitha Dinesh. All rights reserved.
//

import Foundation
import MapKit

typealias AirQualityData = [AirQualityDatum]

struct AirQualityDatum: Codable {
    let dateObserved: String
    let hourObserved: Int
    let localTimeZone, reportingArea, stateCode: String
    let latitude, longitude: Double
    let parameterName: String
    let aqi: Int
    let category: Category
    
    enum CodingKeys: String, CodingKey {
        case dateObserved = "DateObserved"
        case hourObserved = "HourObserved"
        case localTimeZone = "LocalTimeZone"
        case reportingArea = "ReportingArea"
        case stateCode = "StateCode"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case parameterName = "ParameterName"
        case aqi = "AQI"
        case category = "Category"
    }
}

struct Category: Codable {
    let number: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case number = "Number"
        case name = "Name"
    }
}

class AQAnnotations: NSObject, MKAnnotation {
    let stateCode: String
    let aqi: Int
    let coordinate: CLLocationCoordinate2D
    
    init(stateCode: String = "0",
         aqi: Int = 0,
         coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()) {
        self.stateCode = stateCode
        self.aqi = aqi
        self.coordinate = coordinate
    }
}


public class AirQuality : ObservableObject {
    @Published  var aqiData = [AQAnnotations]()
    private var url: URL {
        let urlString = "http://www.airnowapi.org/aq/observation/zipCode/current/?format=application/json&API_KEY=A88AAAD7-486E-4246-B51E-DFF373769427&zipCode="
        guard let zipcode = zipcode else {
            return URL(string: urlString + "95129")!
        }
        return URL(string: urlString + zipcode)!
    }
    
    var zipcode: String? {
        return UserDefaults.standard.zipcode
    }
    
    init() {
        self.getAirQuality()
    }
    
    func getAirQuality() {
        self.unauthenticatedRequest { (data, err) in
            if let err = err as? NSError {
                print("err: \(err.code)")
            }
            let decoder = JSONDecoder()
            guard let data = data else { fatalError() }
            guard let json = try? decoder.decode(AirQualityData.self, from: data) else { fatalError() }
            
            for quality in json {
                print("quality: \(quality)")
            }
            
            var aqAnnotation = AQAnnotations()
            if !json.isEmpty {
                
                aqAnnotation = AQAnnotations(stateCode: json[1].stateCode, aqi: json[1].aqi, coordinate: CLLocationCoordinate2D(latitude: json[1].latitude, longitude: json[1].longitude))
            }
            
            DispatchQueue.main.async {
                self.aqiData.append(aqAnnotation)
            }
        }
    }
    
    func unauthenticatedRequest(data: Data? = nil, completion: @escaping ((Data?, Error?) -> Void)) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60
        let session = URLSession.shared
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request) { data, _, error -> Void in
            guard error == nil else {
                completion(nil, error)
                return
            }
            guard let data = data else {
                completion(nil, nil)
                return
            }
            completion(data, nil)
        }
        task.resume()
    }
}
