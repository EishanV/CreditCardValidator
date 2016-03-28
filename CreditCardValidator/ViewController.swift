//
//  ViewController.swift
//  CreditCardValidator
//
//  Created by Eishan Vijay on 2016-03-27.
//  Copyright © 2016 EishanVijay. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var cardImage: UIImageView!
    @IBOutlet var cardNumber: UITextField!
    @IBOutlet var expirationDate: UITextField!
    @IBOutlet var CVV: UITextField!
    
    var todayDate: NSDate = NSDate()
    var dateFormatter: NSDateFormatter = NSDateFormatter()
    var dateInFormat: String!
    var alertController = UIAlertController()
    
    @IBAction func submitPressed(sender: UIButton) {
        
        // checks to see if the credit card text field has at least 15 characters
        // if so it then goes on to see if its an AMEX since it only has 15, whereas the others have 16
        if (cardNumber.text?.characters.count == 15) {
            if ((cardNumber.text![0...1] == "34" || cardNumber.text![0...1] == "37") && expirationDate.text?.characters.count == 4 && CVV.text?.characters.count == 4) {
                // AMEX card and the user has completed all the fields
                creditCardValidation(cardNumber.text!)
            }
            else {
                // all the fields have not been filled out
                alertController = UIAlertController(title: "Invalid Info!", message: "Please complete the fields before pressing submit.", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
        else if (cardNumber.text?.characters.count == 16 && expirationDate.text?.characters.count == 4 && CVV.text?.characters.count == 3) {
            // all other types of credit cards
            creditCardValidation(cardNumber.text!)
        }
        else {
            // all the fields have not been filled out
            alertController = UIAlertController(title: "Invalid Info!", message: "Please complete the fields before pressing submit.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // text field setup
        cardNumber.delegate = self
        expirationDate.delegate = self
        CVV.delegate = self
        
        // date of phone
        dateFormatter.dateFormat = "MMYY"
        dateInFormat = dateFormatter.stringFromDate(todayDate) // gets the device's current month and year
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        // only allows the user to only enter the expiration date and CVV when they enter a credit card number with a proper format
        if ((textField == CVV || textField == expirationDate)) {
            if (cardNumber.text?.characters.count >= 15) {
                if (cardNumber.text?.characters.count == maxLength(cardNumber.text!)) {
                    return true
                }
            }
            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        // changes the card logo to the CVV logo when the user is editing the CVV text field
        if (textField == CVV) {
            if (cardNumber.text![0...1] == "34" || cardNumber.text![0...1] == "37") {
                cardImage.image = UIImage(named: "AmexCVV")
            }
            else {
                cardImage.image = UIImage(named: "CVV")
            }
        }
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // sets the image back to the card logo
        if (textField == CVV) {
            if (cardNumber.text?.characters.count >= 6) { // additional check
                checkFirstSixDigits(cardNumber.text!)
            }
            else {
                // sets the image to the default generic card logo
                cardImage.image = UIImage(named: "GenericCard")
            }
        }
    }
    
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if(!string.containsOnlyCharactersIn("0123456789")) { // checks to see if the user entered a number
            return false
        }
        
        
        // if the user goes back to change the credit card number, the expiration date and the CVV are reset
        // this is just in case the user decides to use another credit card
        if (cardNumber.text?.characters.count < 15 && (expirationDate.text?.characters.count > 0 || CVV.text?.characters.count > 0)) {
            expirationDate.text = ""
            CVV.text = ""
        }
        
        // calculates the new length of the textfield string (user input)
        let newLength = (textField.text?.utf16.count)! + string.utf16.count - range.length
        
        if (textField == CVV) {
            // restricts the CVV text field to either 4 or 3, depending on their credit card type
            return (cardNumber.text?.characters.count == 15) ? (newLength <= 4) : (newLength <= 3)
        }
        else if (textField == expirationDate) {
            if newLength > 4 {
                // restricts the expiration date to 4 numbers
                return false
            }
            else if (newLength == 4) {
                let date = textField.text! + string
                if (!checkExpiryDate(date)) { // checks if the user entered a valid expiration date
                    expirationDate.text = "" // resets the expiration text field
                    
                    // displays an alert, letting the user know that they've entered an invalid expiration date
                    alertController = UIAlertController(title: "Invalid Expiration Date", message: "Please enter a valid expiration date (MMYY)", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                    
                    return false
                }
            }
        }
        else if (textField == cardNumber) {
            
            if newLength <= 5 {
                // keeps the credit card image to generic if the character count is less than 6
                cardImage.image = UIImage(named: "GenericCard")
            }
            
            if (textField.text?.characters.count >= 6 && string != "") {
                
                //return newLength <= 6 // Bool
                let newString = textField.text! + string
                
                // checks the first six digits for validity
                // if theres a match, the credit card logo also changes accordingly
                return checkFirstSixDigits(newString) && (newLength <= maxLength(textField.text!))
            }
            
        }
        
        
        return true;
    }
    
    func checkExpiryDate (date: String) -> Bool {
        
        if (Int(date[2...3]) >= Int(dateInFormat[2...3])) { // the year entered by the user is either this year or greater
            
            // the user entered the current year and so we must make sure that the month is either this month or greater
            // doesn't allow for expired credit cards to be processed
            if ((Int(date[2...3]) == Int(dateInFormat[2...3])) && (Int(date[0...1]) < Int(dateInFormat[0...1]))) {
                return false
            }
            else if (Int(date[0...1]) > 12) { // the user entered an invalid month
                return false
            }
            
            return true
        }
        else {
            return false
        }
    }
    
    func maxLength (number: String) -> Int {
        
        // returns the max length of a credit card, depending on the card type
        
        if (number[0...1] == "34" || number[0...1] == "37") {
            // AMERICAN EXPRESS
            return 15
        }
        
        return 16
    }
    
    func checkFirstSixDigits (number: String) -> Bool {
        
        // this method check the first six digits of the credit card to see if they're valid and that they correspond to a credit card type
        // if so, the credit card image will change accordingly
        
        var isValid = false
        var cardType = 0
        
        if (number[0...1] == "34" || number[0...1] == "37") {
            // AMERICAN EXPRESS
            isValid = true
            cardType = 1
        }
        else if (number[0...1] == "35") {
            if (Int(number[2...3]) >= 28 && Int(number[2...3]) <= 89) {
                // JCB
                isValid = true
                cardType = 2
            }
        }
        else if (number[0...0] == "2") {
            if (Int(number[1...3]) >= 221 && Int(number[1...3]) <= 720) {
                // MASTERCARD
                isValid = true
                cardType = 3
            }
        }
        else if (number[0...0] == "5") {
            if (Int(number[1...1]) >= 1 && Int(number[1...1]) <= 5) {
                // MASTERCARD
                isValid = true
                cardType = 3
            }
        }
        else if (number[0...0] == "4") {
            // VISA
            isValid = true
            cardType = 4
        }
        else if (number[0...0] == "6") {
            // DISCOVER
            if (number[1...3] == "011") {
                isValid = true
                cardType = 5
            }
            else if (Int(number[1...5]) >= 22126 && Int(number[1...5]) <= 22925) {
                isValid = true
                cardType = 5
            }
            else if (Int(number[1...2]) >= 44 && Int(number[1...2]) <= 49) {
                isValid = true
                cardType = 5
            }
            else if (number[1...1] == "5") {
                isValid = true
                cardType = 5
            }
        }
        
        // change credit card logo
        if (cardType == 0) {
            cardImage.image = UIImage(named: "GenericCard")
        }
        if (cardType == 1) {
            cardImage.image = UIImage(named: "Amex")
        }
        if (cardType == 2) {
            cardImage.image = UIImage(named: "JCB")
        }
        if (cardType == 3) {
            cardImage.image = UIImage(named: "Mastercard")
        }
        if (cardType == 4) {
            cardImage.image = UIImage(named: "Visa")
        }
        if (cardType == 5) {
            cardImage.image = UIImage(named: "Discover")
        }
        
        return isValid
    }
    
    func luhnValidation (number: String) -> Bool {
        
        // this method check to see if the credit card number the user entered is valid
        // according to the Luhn Validation Method
        
        var totalSum = 0
        let numberSize = number.characters.count
        
        let characters = number[0...numberSize - 2].characters
        let reversedString = String(characters.reverse()) // reverse the credit card number without the last digit
        var digit = Int()
        
        for (var i = 0; i < reversedString.characters.count; i++) {
            
            digit = Int(reversedString[i...i])!
            
            if (i % 2 == 1) { // if odd, directly add to total sum
                totalSum += digit
            }
            else {
                digit *= 2
                
                if digit > 9 { // if the number is greater than 9, subtract 9 and then add to total sum
                    totalSum += (digit - 9)
                }
                else {
                    totalSum += digit
                }
            }
        }
        // compares the last digit of the total sum subtracted by 10 to
        // the last digit of the original credit card number
        return (10 - (totalSum % 10)) == Int(number[numberSize - 1...numberSize - 1])
    }
    
    func creditCardValidation (number: String) {
        if (luhnValidation(number)) { // number is valid according to the Luhn Validation Method
            alertController = UIAlertController(title: "Success!", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
        }
        else { // invalid, shows alert accordingly
            alertController = UIAlertController(title: "Invalid Credit Card Number", message: "Please enter a valid credit card number.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
}

extension String {
    
    func containsOnlyCharactersIn(matchCharacters: String) -> Bool {
        // gets the inverted set of the given characters and compares the string to see if it contains them
        // used to see if the user entered a number or not
        let disallowedCharacterSet = NSCharacterSet(charactersInString: matchCharacters).invertedSet
        return self.rangeOfCharacterFromSet(disallowedCharacterSet) == nil
    }
    
    subscript (r: Range<Int>) -> String {
        // allows us to use substrings on strings
        return substringWithRange(Range(start: startIndex.advancedBy(r.startIndex), end: startIndex.advancedBy(r.endIndex)))
    }
}
