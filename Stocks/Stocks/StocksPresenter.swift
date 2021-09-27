//
//  StocksPresenter.swift
//  Stocks
//
//  Created by Михаил Зиновьев on 04.09.2021.
//

import Foundation


protocol StocksPresenterProtocol: AnyObject {
    func attach(_ view: StocksViewControllerProtocol)
    func getCompanies(type: CompanyType)
    func getQuoteLogo(symbol: String)
    func getQuote(symbol: String)
}

enum CompanyType: String {
    case mostactiveCompanyType = "mostactive"
    case gainersCompanyType = "gainers"
    case losersCompanyType = "losers"
}

class StocksPresenter {
    
    private weak var view: StocksViewControllerProtocol?
    private lazy var networkManager = NetworkManager()
}

extension StocksPresenter: StocksPresenterProtocol {
    
    func attach(_ view: StocksViewControllerProtocol) {
        self.view = view
    }
    
    func getCompanies(type: CompanyType) {
        networkManager.requestCompanies(for: type.rawValue) { [weak self] result in
            self?.view?.updateCompanies(newCompanies: result)
        } errorHandler: { [weak self] title, error in
            self?.view?.showAlert(title: title, message: error)
        }
    }
    
    func getQuoteLogo(symbol: String) {
        networkManager.requestQuoteLogo(for: symbol) { [weak self] result in
            self?.view?.updateImage(stringUrl: result)
        } errorHandler: { [weak self] title, error in
            self?.view?.showAlert(title: title, message: error)
        }
    }
    
    func getQuote(symbol: String) {
        networkManager.requestQuote(for: symbol) { [weak self] result in
            self?.view?.updateStockInfo(company: result)
        } errorHandler: { [weak self] title, error in
            self?.view?.showAlert(title: title, message: error)
        }
    }
}
