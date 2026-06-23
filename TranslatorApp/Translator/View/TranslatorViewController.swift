//
//  TranslatorViewController.swift
//  TranslatorApp
//
//  Created by Mac on 23/06/2026.
//

import UIKit

class TranslatorViewController: UIViewController {

    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var translateButton: UIButton!
    @IBOutlet weak var pillView: UIView!
    @IBOutlet weak var inputCardView: UIView!
    @IBOutlet weak var outputCardView: UIView!
    @IBOutlet weak var sourceLanguageLabel: UILabel!
    @IBOutlet weak var targetLanguageLabel: UILabel!

    private let availableLanguages: [(name: String, code: String)] = [
        ("English", "en"),
        ("Spanish", "es"),
        ("French", "fr"),
        ("German", "de"),
        ("Italian", "it"),
        ("Portuguese", "pt"),
        ("Urdu", "ur"),
        ("Hindi", "hi"),
        ("Arabic", "ar"),
        ("Chinese", "zh"),
        ("Japanese", "ja"),
        ("Russian", "ru")
    ]

    private var sourceLanguageCode = "en"
    private var targetLanguageCode = "es"

    private let googleAPIKey = "AIzaSyCSKgSOOavp9vbYIy2vHnBxXQN2_URjWZE"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCornerRadius()
        setupLanguageTapGestures()
    }

    private func setupCornerRadius() {
        pillView.layer.cornerRadius = 30
        inputCardView.layer.cornerRadius = 16
        outputCardView.layer.cornerRadius = 16
    }

    private func setupLanguageTapGestures() {
        sourceLanguageLabel.isUserInteractionEnabled = true
        targetLanguageLabel.isUserInteractionEnabled = true

        let sourceTap = UITapGestureRecognizer(target: self, action: #selector(sourceLanguageTapped))
        sourceLanguageLabel.addGestureRecognizer(sourceTap)

        let targetTap = UITapGestureRecognizer(target: self, action: #selector(targetLanguageTapped))
        targetLanguageLabel.addGestureRecognizer(targetTap)
    }

    @objc private func sourceLanguageTapped() {
        presentLanguagePicker(title: "Translate from") { [weak self] selected in
            guard let self = self else { return }
            self.sourceLanguageCode = selected.code
            self.sourceLanguageLabel.text = selected.name
        }
    }

    @objc private func targetLanguageTapped() {
        presentLanguagePicker(title: "Translate to") { [weak self] selected in
            guard let self = self else { return }
            self.targetLanguageCode = selected.code
            self.targetLanguageLabel.text = selected.name
        }
    }

    private func presentLanguagePicker(title: String, onSelect: @escaping ((name: String, code: String)) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        for language in availableLanguages {
            alert.addAction(UIAlertAction(title: language.name, style: .default) { _ in
                onSelect(language)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    @IBAction func translateButtonTapped(_ sender: UIButton) {
        guard let textToTranslate = inputTextView.text, !textToTranslate.isEmpty else { return }
        translate(text: textToTranslate, from: sourceLanguageCode, to: targetLanguageCode) { [weak self] result in
            DispatchQueue.main.async {
                self?.outputTextView.text = result
            }
        }
    }

    private func translate(text: String, from sourceLang: String, to targetLang: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=\(googleAPIKey)") else {
            completion("Error: could not build request")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "q": text,
            "source": sourceLang,
            "target": targetLang,
            "format": "text"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let translations = dataDict["translations"] as? [[String: Any]],
                   let first = translations.first,
                   let translatedText = first["translatedText"] as? String {
                    completion(translatedText)
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let errorDict = json["error"] as? [String: Any],
                          let message = errorDict["message"] as? String {
                    completion("API Error: \(message)")
                } else {
                    completion("Error: unexpected response")
                }
            } catch {
                completion("Error: \(error.localizedDescription)")
            }
        }.resume()
    }
}
