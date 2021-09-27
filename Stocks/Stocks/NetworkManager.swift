//
//  NetworkManager.swift
//  Stocks
//
//  Created by Михаил Зиновьев on 04.09.2021.
//

import Foundation


class NetworkManager {
    
    private enum Constants {
        static let scheme = "https"
        static let host = "cloud.iexapis.com"
        static let endpointVersion = "stable"
        static let token = "pk_8ede7778d1df4406ac76b417f5d39aaf"
    }
    
    func requestCompanies(for type: String, completionHandler: @escaping ([String: String]) -> Void, errorHandler: @escaping (String, String) -> Void) {
            
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.scheme
        urlComponents.host = Constants.host
        urlComponents.path = "/\(Constants.endpointVersion)/stock/market/list/\(type)"
        urlComponents.queryItems = [
            URLQueryItem(name: "token", value: Constants.token)
        ]

        guard let url: URL = urlComponents.url else { return }
     
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let httpResponse = (response as? HTTPURLResponse) else {
                errorHandler("Error", "unknown responce")
                return
            }
            guard
                error == nil,
                httpResponse.statusCode == 200,
                let data = data
            else {
                errorHandler("Network error", "statusCode: \(httpResponse.statusCode)")
                return
            }
            self?.parseCompanies(data: data, completionHandler: completionHandler, errorHandler: errorHandler)
        }
        
        dataTask.resume()
    }
    
    func requestQuoteLogo(for symbol: String, completionHandler: @escaping (String) -> Void, errorHandler: @escaping (String, String) -> Void) {
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.scheme
        urlComponents.host = Constants.host
        urlComponents.path = "/\(Constants.endpointVersion)/stock/\(symbol)/logo"
        urlComponents.queryItems = [
            URLQueryItem(name: "token", value: Constants.token)
        ]

        guard let url: URL = urlComponents.url else { return }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let httpResponse = (response as? HTTPURLResponse) else {
                errorHandler("Error", "Unknown responce")
                return
            }
            guard
                error == nil,
                httpResponse.statusCode == 200,
                let data = data
            else {
                errorHandler("Network error", "statusCode: \(httpResponse.statusCode)")
                return
            }
            self?.parseImageLink(data: data, completionHandler: completionHandler, errorHandler: errorHandler)
        }
        dataTask.resume()
    }
    
    func requestQuote(for symbol: String, completionHandler: @escaping (Company) -> Void, errorHandler: @escaping (String, String) -> Void) {
            
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.scheme
        urlComponents.host = Constants.host
        urlComponents.path = "/\(Constants.endpointVersion)/stock/\(symbol)/quote"
        urlComponents.queryItems = [
            URLQueryItem(name: "token", value: Constants.token)
        ]

        guard let url: URL = urlComponents.url else { return }
     
        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let httpResponse = (response as? HTTPURLResponse) else {
                errorHandler( "Error", "unknown responce")
                return
            }
            guard
                error == nil,
                httpResponse.statusCode == 200,
                let data = data
            else {
                errorHandler("Network error", "statusCode: \(httpResponse.statusCode)")
                return
            }
            self?.parseQuote(data: data, completionHandler: completionHandler, errorHandler: errorHandler)
        }
        dataTask.resume()
    }
}

// MARK: - Private
private extension NetworkManager {
    
    func parseCompanies(data: Data, completionHandler: @escaping ([String: String]) -> Void, errorHandler: @escaping (String, String) -> Void) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [[String: Any]]
            else {
                errorHandler("Error", "Invalid JSON format")
                return
            }
            var newCompanies: [String: String] = ["": ""]
            for companyJson in json {
                guard
                    let companyName = companyJson["companyName"] as? String,
                    let companySymbol = companyJson["symbol"] as? String
                    else { continue }

                newCompanies[companyName] = companySymbol
            }
            completionHandler(newCompanies)
        } catch {
            errorHandler("Error", "JSON parsing error")
        }
    }
    
    func parseImageLink(data: Data, completionHandler: (String) -> Void, errorHandler: (String, String) -> Void) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let url = json["url"] as? String
            else {
                errorHandler("Error", "Invalid JSON format")
                return
            }
            completionHandler(url)
        } catch {
            errorHandler("Error", "JSON parsing error")
        }
    }
    
    func parseQuote(data: Data, completionHandler: (Company) -> Void, errorHandler: (String, String) -> Void) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
                errorHandler("Error", "Invalid JSON format")
                return
            }
            completionHandler(Company(companyName: companyName,
                                      companySymbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange))
        } catch {
            errorHandler("Error", "JSON parsing error")
        }
    }
}
