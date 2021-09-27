//
//  StocksViewController.swift
//  Stocks
//
//  Created by Михаил Зиновьев on 03.09.2021.
//

import UIKit
import Kingfisher


protocol StocksViewControllerProtocol: AnyObject {
    func showAlert(title: String, message: String)
    func updateCompanies(newCompanies: [String: String])
    func updateImage(stringUrl: String)
    func updateStockInfo(company: Company)
}

class StocksViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companySymbolImage: UIImageView!
    @IBOutlet weak var companyTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - private properties
    
    private let presenter = StocksPresenter()
    
    private var companies: [String: String] = ["": ""] {
        didSet {
            self.companyPickerView.reloadAllComponents()
        }
    }
    private var imageStringUrl: String? {
        didSet {
            DispatchQueue.main.async { [self] in
                guard
                    imageStringUrl != "",
                    let url = imageStringUrl
                else {
                    companySymbolImage.isHidden = true
                    return
                }
                companySymbolImage.isHidden = false
                companySymbolImage.kf.setImage(with: URL(string: url))
            }
        }
    }
    private var imageUrl: URL?
    
    // MARK: - IBActions
    @IBAction func companyTypeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        
        case 0:
            presenter.getCompanies(type: .mostactiveCompanyType)
        case 1:
            presenter.getCompanies(type: .gainersCompanyType)
        case 2:
            presenter.getCompanies(type: .losersCompanyType)
        default:
            presenter.getCompanies(type: .mostactiveCompanyType)
        }
    }
    
    // MARK: - Private
    private func displayStockInfo(companyName: String, symbol: String, price: Double, priceChange: Double) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.companyNameLabel.text = companyName
            self.companySymbolLabel.text = symbol
            self.priceLabel.text = String(price)
            self.priceChangeLabel.text = String(priceChange)
            self.updatePriceChangeLabelColor(with: priceChange)
        }
    }
    
    private func requestQuoteUpdate() {
        self.activityIndicator.startAnimating()
        
        self.companyNameLabel.text = "-"
        self.companySymbolLabel.text = "-"
        self.priceLabel.text = "-"
        self.priceChangeLabel.text = "-"
        self.priceChangeLabel.textColor = .black
        
        guard companies.count != 0 else {
            showErrorAlert(errorTitle: "Error", message: "No companies")
            return
        }
        
        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let companyArray = Array(self.companies.values)
        if companyArray.indices.contains(selectedRow) {
            let selectedSymbol = companyArray[selectedRow]
            
            presenter.getQuote(symbol: selectedSymbol)
            presenter.getQuoteLogo(symbol: selectedSymbol)
        } else {
            showErrorAlert(errorTitle: "Error", message: "No companies")
        }
    }
    
    private func updatePriceChangeLabelColor(with priceChange: Double){
        if priceChange > 0 {
            priceChangeLabel.textColor = .systemGreen
        } else if priceChange < 0 {
            priceChangeLabel.textColor = .systemRed
        } else {
            priceChangeLabel.textColor = .black
        }
    }
    
    private func showErrorAlert(errorTitle: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: errorTitle, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.activityIndicator.stopAnimating()
        }
    }
}

// MARK: - Life cycle
extension StocksViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.attach(self)
        setupViews()
        presenter.getCompanies(type: .mostactiveCompanyType)
    }
}

// MARK: - Setup Views
private extension StocksViewController {
    
    func setupViews() {
        self.view.backgroundColor = .systemGray6
        self.navigationItem.title = "Stocks"

        companyTypeSegmentedControl.setTitle("Popular", forSegmentAt: 0)
        companyTypeSegmentedControl.setTitle("Gainers", forSegmentAt: 1)
        companyTypeSegmentedControl.setTitle("Losers", forSegmentAt: 2)
        
        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
    }
}

// MARK: - StocksViewControllerProtocol
extension StocksViewController: StocksViewControllerProtocol {
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.activityIndicator.stopAnimating()
        }
    }
    
    func updateCompanies(newCompanies: [String: String]) {
        DispatchQueue.main.async {
            self.companies.removeAll()
            self.companies = newCompanies
            self.companies.removeValue(forKey: "")
            
            self.requestQuoteUpdate()
        }
    }
    
    func updateImage(stringUrl: String) {
        self.imageStringUrl = stringUrl
    }
    
    func updateStockInfo(company: Company) {
        displayStockInfo(companyName: company.companyName,
                         symbol: company.companySymbol,
                         price: company.price,
                         priceChange: company.priceChange)
    }
}

// MARK: - UIPickerViewDataSource
extension StocksViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.keys.count
    }
}

// MARK: - UIPickerViewDelegate
extension StocksViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(self.companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.activityIndicator.startAnimating()
        
        let selectedSymbol = Array(self.companies.values)[row]
        presenter.getQuote(symbol: selectedSymbol)
        presenter.getQuoteLogo(symbol: selectedSymbol)
    }
}
