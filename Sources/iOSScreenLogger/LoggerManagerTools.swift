//
//  LoggerManagerTools.swift
//  NMG News
//
//  Created by Joey Sun on 2024/8/26.
//

import UIKit
import JavaScriptCore
class LoggerManagerTools: NSObject {
    // MARK: - URL
    class func printRequestURLLog(url: URL?) {
        var text = ""
        guard let url = url else { return }
        text += "\n========== Start Sending Request ==========\n"
        text += "\n\nRequest URL:\n\(url.absoluteString)"
        if let beautifulURLString = url.absoluteString.removingPercentEncoding {
            text += "\n\nBeautificated URL: \(beautifulURLString)\n"
        }

        let components = URLComponents(string: url.absoluteString)
        if components?.queryItems?.count ?? 0 > 0 {
            text += "\n\nBody:\n"
            var dict = [String: Any]()
            components?.queryItems?.forEach { paramPair in
                dict[paramPair.name] = paramPair.value
            }
            text += ModelTransformJsonTools.toJSONString(dict, prettyPrint: true) ?? ""
            text += "\n"
        } else {
            text += "\n\nNo Body Found"
        }

        text += "\n\n========== Request Sent ==========\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"

        let component = url.path.split(separator: "?")
        if component.count == 2 {
            Logger.sharedManager.printLog(title: "Request: \(component.first!) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
        } else {
            Logger.sharedManager.printLog(title: "Request: \(url.path) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
        }
    }

    class func printResponseURLLog(_ url: URL?,_ res: HTTPURLResponse?, _ data: Data?,_ error: Error?) {
        var text = ""
        guard let url = url else { return }
        text += "\n========== Receive Response ==========\n"
        text += "\nRequest URL:\n\(url.absoluteString)\n"


        if let error = error {
            text += "\nFound Error:\n\(error.localizedDescription)"
        } else {
            if let statusCode = res?.statusCode {
                text += "\n\nResponse Code:\n\(statusCode)"
            }
            if let data = data,
               let aJson =
                WXJSJsonConvert.convertJson(String(data: data, encoding: String.Encoding.utf8)) {
                guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: aJson, options: .prettyPrinted) else { return }
                guard let jsonString = String(data: prettyJsonData, encoding: String.Encoding.utf8) else { return }

                text += "\n\nResponse:\n\(jsonString)"
            }
        }

        text += "\n\n==========End Of Response==========\n"

        let component = url.path.split(separator: "?")

        var statusCode = "N/A"
        if let value = res?.statusCode {
            statusCode = String(value)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"

        if component.count == 2 {
            Logger.sharedManager.printLog(title: "Status: \(statusCode), " + "Response: \(component.first!) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
        } else {
            Logger.sharedManager.printLog(title: "Response: \(url.path) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
        }
    }

    // MARK: - URLRequest
    class func printRequestLog(req: URLRequest?) {
        var text = ""
        guard let aReq = req, let url = aReq.url else { return }
        text += "\n========== Start Sending Request =========="
        text += "\nRequest URL:\n\(url.absoluteString)\n"
        if let beautifulURLString = url.absoluteString.removingPercentEncoding {
            text += "\n\nBeautificated URL: \(beautifulURLString)"
        }

        if let HTTPMethod = aReq.httpMethod {
            text += "\n\nMethod: \(HTTPMethod)"
        }

        if let headers = aReq.allHTTPHeaderFields, headers.count > 0 {
            text += "\n\nHeaders:\n"
            for (key, value) in headers {
                text += "\(key): \(value)"
            }
        }

        if let body = aReq.httpBody, let rawParams = String(data: body, encoding: String.Encoding.utf8), rawParams.count > 0 {
            let params = rawParams.components(separatedBy: "&")
            text += "\n\nBody:\n"
            if params.count > 0 {
                for param in params {
                    let paramPair = param.components(separatedBy: "=")
                    if paramPair.count < 2 { continue }
                    text += "\(paramPair[0]): \(paramPair[1])"
                }
            } else {
                text += "\n\nNo Body Found"
            }
        }

        text += "\n\n========== Request Sent ==========\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"

        if let path = req?.url?.path {
            let component = path.split(separator: "?")
            if component.count == 2 {
                Logger.sharedManager.printLog(title: "Request: \(component.first!) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
            } else {
                Logger.sharedManager.printLog(title: "Request: \(path) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
            }
        }
    }

    class func printResponseLog(_ req: URLRequest, res: HTTPURLResponse?,_ data: Data?,_ error: Error?) {
        var text = ""
        guard let url = req.url else { return }
        text += "\n========== Receive Response ==========\n"
        text += "\nRequest URL:\n\(url.absoluteString)"

        if let error = error {
            text += "\nFound Error:\n\(error.localizedDescription)"
        } else {
            if let statusCode = res?.statusCode {
                text += "\n\nResponse Code:\n\(statusCode)"
            }

            if let data = data,
                let aJson =
                WXJSJsonConvert.convertJson(String(data: data, encoding: String.Encoding.utf8)) {
                guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: aJson, options: .prettyPrinted) else { return }
                guard let jsonString = String(data: prettyJsonData, encoding: String.Encoding.utf8) else { return }

                text += "\n\nResponse:\n\(jsonString)"
            }
        }

        text += "\n\n==========End Of Response==========\n"
        if let path = req.url?.path {
            let component = path.split(separator: "?")

            var statusCode = "N/A"
            if let value = res?.statusCode {
                statusCode = String(value)
            }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"

            if component.count == 2 {
                Logger.sharedManager.printLog(title: "Status: \(statusCode), " + "Response: \(component.first!) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
            } else {
                Logger.sharedManager.printLog(title: "Response: \(path) (\(dateFormatter.string(from: Date())))", text: text, type: .API)
            }
        }
    }
}

// MARK: - WXJSJsonConvert
class WXJSJsonConvert {
    fileprivate static var JSConvertJsonScript: String = ""

    static func convertJson(_ jsonString: String?) -> Any? {
        if let aJsonStr = jsonString?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), !aJsonStr.isEmpty {
            let js = "function convertJsonStr(jsonStr){try{var obj=JSON.parse(jsonStr);var newObj=parseObj(obj);var result=JSON.stringify(newObj);return result}catch(e){return\"\"}return\"\"}function parseObj(obj){if(obj==null){return obj}else if(obj.constructor==Array){return parseArray(obj)}else if(obj.constructor==Object){return parseDictionay(obj)}else if(typeof obj==\"number\"&&!(obj%1===0)){return\"\"+obj}return obj}function parseArray(array){for(var i in array){array[i]=parseObj(array[i])}return array}function parseDictionay(dictionay){for(var key in dictionay){dictionay[key]=parseObj(dictionay[key])}return dictionay}"
            //            JSJsonConvert.loadJavaScript()
            let context = JSContext()
            _ = context?.evaluateScript("\(js)")
            context?.setObject(aJsonStr, forKeyedSubscript: "jsonString" as NSCopying & NSObjectProtocol)
            //            context.evaluateScript("\(JSJsonConvert.JSConvertJsonScript)")
            if let result = context?.evaluateScript("convertJsonStr(jsonString);"),
                let convertedJsonStr = result.toString(), !convertedJsonStr.isEmpty, !result.isUndefined, !result.isNull {
                if let data = convertedJsonStr.data(using: String.Encoding.utf8),
                    let convestedJSON = try? JSONSerialization.jsonObject(with: data, options: []) {
                    return convestedJSON as Any
                }
            }
            if let data = aJsonStr.data(using: String.Encoding.utf8),
                let convestedJSON = try? JSONSerialization.jsonObject(with: data, options: []) {
                return convestedJSON as Any
            }
        }
        return nil
    }
}
