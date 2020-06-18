//
//  REST.swift
//  Carangas
//
//  Created by William Tomaz on 16/06/20.
//  Copyright © 2020 Eric Brito. All rights reserved.
//

import Foundation

enum CarError {
    case url
    case taskError(error: Error)
    case noResponse
    case noData
    case responseStatusCode(code: Int)
    case invalidJSON
}

enum RESTOperation {
    case save
    case update
    case delete
}

class REST {
    
    private static let basePath = "https://carangas.herokuapp.com/cars" //link da api
    
    private static let configuration: URLSessionConfiguration = {
       let config = URLSessionConfiguration.default // default salva em cache ou local no celular
        config.allowsCellularAccess = false //nao permite usar o 4g
        config.httpAdditionalHeaders = ["Content-Type": "application/json"] //definindo que os dados trafegados sao do tipo json, *com um dicionario
        config.timeoutIntervalForRequest = 30.0
        config.httpMaximumConnectionsPerHost = 5
        return config
    }()
    
    private static let session = URLSession(configuration: configuration) //pegando sessao criada acima //URLSession.shared //criando uma sessao compartilhada, pois pode ser usada en qualquer lugar do code
    
    class func loadCars(onComplete: @escaping ([Car]) -> Void, onError: @escaping (CarError) -> Void) { //retornando uma closure com parametro de array de Car //funcao nao precisa de classe criada, iniciando dessa forma
        guard let url = URL(string: basePath) else {
            onError(.url)
            return
        } //instanciando a url e chamando o enum de erros
        
        let dataTask = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in //retornado/url response e error
            if error == nil {
                guard let response = response as? HTTPURLResponse else {
                    onError(.noResponse)
                    return
                } // pegando a resposta
                if response.statusCode == 200 {
                    guard let data = data else {
                        onError(.responseStatusCode(code: response.statusCode))
                        return
                    }
                    do {
                    let cars = try JSONDecoder().decode([Car].self, from: data) // tentando decodificar o valor em um json de array de Car
                        onComplete(cars)
                    } catch {
                        print(error.localizedDescription)
                        onError(.invalidJSON)
                    }
                } else {
                    print ("Algum status inválido pelo servidor!")
                }
                
            } else {
                onError(.taskError(error: error!))
            }
        }
        dataTask.resume() //iniciando a task
    }
    
    class func loadBrands(onComplete: @escaping ([Brand]?) -> Void) { //retornando uma closure com parametro de array de Car //funcao nao precisa de classe criada, iniciando dessa forma
        guard let url = URL(string: "https://fipeapi.appspot.com/api/1/carros/marcas.json") else {
            onComplete(nil)
            return
        } //instanciando a url e chamando o enum de erros
        
        let dataTask = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in //retornado/url response e error
            if error == nil {
                guard let response = response as? HTTPURLResponse else {
                    onComplete(nil)
                    return
                } // pegando a resposta
                if response.statusCode == 200 {
                    guard let data = data else {return}
                    do {
                        let brands = try JSONDecoder().decode([Brand].self, from: data) // tentando decodificar o valor em um json de array de Car
                        onComplete(brands)
                    } catch {
                        print(error.localizedDescription)
                        onComplete(nil)
                    }
                } else {
                    print ("Algum status inválido pelo servidor!")
                }
                
            } else {
                onComplete(nil)
            }
        }
        dataTask.resume() //iniciando a task
    }
    
    class func save(car: Car, onComplete: @escaping (Bool) -> Void) { //Inserindo um carro na api
       applyOperation(car: car, operation: .save, onComplete: onComplete)
    }
    class func update(car: Car, onComplete: @escaping (Bool) -> Void) { //Inserindo um carro na api
       applyOperation(car: car, operation: .update, onComplete: onComplete)
    }
    class func delete(car: Car, onComplete: @escaping (Bool) -> Void) {
        applyOperation(car: car, operation: .delete, onComplete: onComplete)
    }
    
    private class func applyOperation(car: Car,operation: RESTOperation, onComplete: @escaping (Bool) -> Void) {
        
        let urlString = basePath + "/" + (car._id ?? "")
        guard let url = URL(string: urlString) else {
            onComplete(false)
            return
        } //instanciando a url e chamando o retorno booleano
        var request = URLRequest(url: url)
        var httpMethod: String = ""
        
        switch operation {
            case .save:
                httpMethod = "POST"
            case .update:
                httpMethod = "PUT"
            case .delete:
                httpMethod = "DELETE"
        }
        request.httpMethod = httpMethod
        guard let json = try? JSONEncoder().encode(car) else {
            onComplete(false)
            return
        } //codificando um car
        request.httpBody = json
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if error == nil {
                guard let response = response as? HTTPURLResponse, response.statusCode == 200, let _ = data else {
                    onComplete(false)
                    return
                }
                onComplete(true)
            } else {
                onComplete(false)
            }
        }
        dataTask.resume()
    }
}
