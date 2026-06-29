//
//  TranslatorViewController.swift
//  TranslatorApp
//
//  Created by Mac on 23/06/2026.
//

//
//  TranslatorViewController.swift
//  TranslatorApp
//
//  Created by Mac on 23/06/2026.
//

import UIKit
import MLKitTranslate

class TranslatorViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var translateButton: UIButton!
    @IBOutlet weak var pillView: UIView!
    @IBOutlet weak var inputCardView: UIView!
    @IBOutlet weak var outputCardView: UIView!
    @IBOutlet weak var sourceLanguageLabel: UILabel!
    @IBOutlet weak var targetLanguageLabel: UILabel!
    @IBOutlet weak var inputPlaceholderLabel: UILabel!
    @IBOutlet weak var outputPlaceholderLabel: UILabel!
    @IBOutlet weak var inputCardLanguageLabel: UILabel!   
    @IBOutlet weak var outputCardLanguageLabel: UILabel!


    private let availableLanguages: [(name: String, language: TranslateLanguage)] = [
        ("English", .english),
        ("Spanish", .spanish),
        ("French", .french),
        ("German", .german),
        ("Italian", .italian),
        ("Portuguese", .portuguese),
        ("Urdu", .urdu),
        ("Hindi", .hindi),
        ("Arabic", .arabic),
        ("Chinese", .chinese),
        ("Japanese", .japanese),
        ("Russian", .russian),
        ("Korean", .korean),
        ("Turkish", .turkish),
        ("Dutch", .dutch),
        ("Polish", .polish),
        ("Vietnamese", .vietnamese),
        ("Thai", .thai),
        ("Indonesian", .indonesian),
        ("Bengali", .bengali),
        ("Persian", .persian),
        ("Greek", .greek),
        ("Hebrew", .hebrew),
        ("Swedish", .swedish),
        ("Ukrainian", .ukrainian)
    ]

    private var sourceLanguage: TranslateLanguage = .english
    private var targetLanguage: TranslateLanguage = .spanish

    override func viewDidLoad() {
        super.viewDidLoad()

        inputTextView.delegate = self
        outputTextView.delegate = self

        view.backgroundColor = .white
        setupCornerRadius()
        setupLanguageTapGestures()
        
        inputCardLanguageLabel.text = availableLanguages.first(where: { $0.language == sourceLanguage })?.name
        outputCardLanguageLabel.text = availableLanguages.first(where: { $0.language == targetLanguage })?.name
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView == inputTextView {
            inputPlaceholderLabel.isHidden = !textView.text.isEmpty
        } else if textView == outputTextView {
            outputPlaceholderLabel.isHidden = !textView.text.isEmpty
        }
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
            self.sourceLanguage = selected.language
            self.sourceLanguageLabel.text = selected.name
            self.inputCardLanguageLabel.text = selected.name
        }
    }

    @objc private func targetLanguageTapped() {
        presentLanguagePicker(title: "Translate to") { [weak self] selected in
            guard let self = self else { return }
            self.targetLanguage = selected.language
            self.targetLanguageLabel.text = selected.name
            self.outputCardLanguageLabel.text = selected.name
        }
    }

    private func presentLanguagePicker(title: String, onSelect: @escaping ((name: String, language: TranslateLanguage)) -> Void) {
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

        outputTextView.text = "Translating..."
        outputPlaceholderLabel.isHidden = true
        translateButton.isEnabled = false

        translate(text: textToTranslate, from: sourceLanguage, to: targetLanguage) { [weak self] result in
            DispatchQueue.main.async {
                self?.translateButton.isEnabled = true
                self?.outputTextView.text = result
                self?.outputPlaceholderLabel.isHidden = !result.isEmpty
            }
        }
    }

    private func translate(text: String, from sourceLang: TranslateLanguage, to targetLang: TranslateLanguage, completion: @escaping (String) -> Void) {
        let options = TranslatorOptions(sourceLanguage: sourceLang, targetLanguage: targetLang)
        let translator = Translator.translator(options: options)

        let conditions = ModelDownloadConditions(allowsCellularAccess: true, allowsBackgroundDownloading: true)

        translator.downloadModelIfNeeded(with: conditions) { error in
            if let error = error {
                completion("Error downloading language model: \(error.localizedDescription)")
                return
            }

            translator.translate(text) { translatedText, error in
                if let error = error {
                    completion("Translation error: \(error.localizedDescription)")
                    return
                }
                completion(translatedText ?? "Error: no translation returned")
            }
        }
    }
}
