//
//  ModelTransformJsonTools.swift
//  NMG News
//
//  Created by Joey Sun on 2024/8/26.
//

import Foundation

class ModelTransformJsonTools {
    /// Converts an Object to a JSON string with option of pretty formatting
    public static func toJSONString(_ JSONObject: Any, prettyPrint: Bool) -> String? {
        let options: JSONSerialization.WritingOptions = prettyPrint ? .prettyPrinted : []
        if let JSON = ModelTransformJsonTools.toJSONData(JSONObject, options: options) {
            return String(data: JSON, encoding: String.Encoding.utf8)
        }

        return nil
    }

    /// Converts an Object to JSON data with options
    public static func toJSONData(_ JSONObject: Any, options: JSONSerialization.WritingOptions) -> Data? {
        if JSONSerialization.isValidJSONObject(JSONObject) {
            let JSONData: Data?
            do {
                JSONData = try JSONSerialization.data(withJSONObject: JSONObject, options: options)
            } catch let error {
                print(error)
                JSONData = nil
            }

            return JSONData
        }

         return nil
    }

    /// Convert a JSON String into an Object using NSJSONSerialization
    public static func parseJSONString(JSONString: String) -> Any? {
        let data = JSONString.data(using: String.Encoding.utf8, allowLossyConversion: true)
        if let data = data {
            let parsedJSON: Any?
            do {
                parsedJSON = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            } catch let error {
                print(error)
                parsedJSON = nil
            }
            return parsedJSON
        }

        return nil
    }
}
