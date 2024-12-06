//
//  ZeroIntelligenceTraders.swift
//  
//  This file is part of the Zero Intelligence Traders program, an Agent Based Model (ABM) implementation based on Gode & Sunder (1993) and Axtell (2009).
//  Copyright (C) 2024 John Silver (jcsilver3@gmail.com, jsilver9@gmu.edu)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//
import SwiftUI
/* Trader class to pass-by-reference */
class Trader: Identifiable {
    /* type declarations are implicit, all of these are integers */
    let id = UUID()
    var isSeller = false
    var quantityHeld = 0
    var value = 0 
    var price = 0
    
    init(isSeller: Bool, quantityHeld: Int) {
        self.isSeller = isSeller 
        self.quantityHeld = quantityHeld
    }
    init(quantityHeld: Int, price: Int) {
        self.quantityHeld = quantityHeld
        self.price = price
    }
    init(price: Int) {
        self.price = price
    }
}
struct Trade {
    var buyer: Trader
    var seller: Trader
    var quantity = 0
    var price = 0
}
class GraphDatum: Identifiable {
    var id = UUID()
    var cat = "Category"
    var key = 0
    var value = 0
    init(key: Int, value: Int, cat: String) {
        self.key = key
        self.value = value
        self.cat = cat
    }
}
class GraphData: Identifiable {
    var id = UUID()
    var data: [GraphDatum]
    init() {
        self.data = [GraphDatum]()
    }
    func updateValue(value: Int, forKey: Int, cat: String) {
        if !self.data.contains(where: {$0.key == forKey && $0.cat == cat}) {
            self.data.append(GraphDatum(key: forKey, value: 0, cat: cat))
        }
        self.data = data.map({
            if $0.key == forKey && $0.cat == cat{
                return GraphDatum(key: forKey, value: $0.value + 1, cat: cat)
            } else {
                return $0
            }
        })
    }
    func toArray() -> [[Int]] {
        var out = [[Int]]()
        for datum in data {
            out.append([datum.key, datum.value])
        }
        return out
    }
}
class Market: ObservableObject {
    @Published var numBuyers = 2000
    @Published var numSellers = 4000
    @Published var maxTrades = 20000
    @Published var maxBuyerValue = 50
    @Published var maxSellerValue = 50
    @Published var buyers = [Trader]()   
    @Published var sellers = [Trader]()
    @Published var trades = [Trade]()
    init() {
        
    }
    init(numBuyers: Int = 0, numSellers: Int = 0, maxTrades: Int = 0) {
        self.numBuyers = numBuyers
        self.numSellers = numSellers
        self.maxTrades = maxTrades                            
    }
    func clearData() {
        self.buyers = [Trader]()
        self.sellers = [Trader]()
        self.trades = [Trade]()
        self.objectWillChange.send()
    }
    
}
class Sim: ObservableObject {
    @Published var market = Market()
    @Published var pctDone = 0.0
    @Published var startTime = DispatchTime.now()
    @Published var endTime = DispatchTime.now()
    @Published var elapsedTime = 0.0
    @Published var message: String = ""
    @Published var graphData = GraphData()
    var isRunning = false
    init() {
    }
    
    func reset() {
        self.message = ""
        self.market.clearData()
        self.graphData = GraphData()
        self.startTime = DispatchTime.now()
        self.endTime = DispatchTime.now()
        self.elapsedTime = 0.0
        self.objectWillChange.send()
    }
    func initAgents() {
        
        print("Start Init Agents \(Date.now)")
        market.buyers.reserveCapacity(market.numBuyers)
        for _ in 0...market.numBuyers {
            let buyer = Trader(price: Int.random(in:1...market.maxBuyerValue))
            market.buyers.append(buyer)
        }
        market.sellers.reserveCapacity(market.numSellers)
        for _ in 0...market.numSellers {
            let seller = Trader(quantityHeld: 1, price: Int.random(in: 1...market.maxSellerValue))
            market.sellers.append(seller)
        }
        
        print(Date.now)
        print("End Init Agents \(Date.now)")
    }
    func doTrades() {
        print("Start DoTrades \(Date.now)")
        for _ in 0..<market.maxTrades {
            
            let buyer = market.buyers.randomElement()!
            let seller = market.sellers.randomElement()!
            
            if seller.quantityHeld > 0 && buyer.quantityHeld == 0 && seller.price <= buyer.price {
                let price = Int.random(in: seller.price...buyer.price)
                buyer.quantityHeld = 1
                seller.quantityHeld = 0
                let trade = Trade(buyer: buyer, seller: seller, quantity: 1, price: price)
                market.trades.append(trade)
            }
        }
        print("End DoTrades \(Date.now)")
    }
    func calculateStats() {
        print("Start CalcStats \(Date.now)")
        var tradeCount = 0
        var totalQuantity = 0
        var totalPrice = 0 
        var totalPrice2 = 0.00
        var averagePrice = 0.00
        var stdev = 0.00
        var data = [[Int]]()
        for trade in market.trades {
            tradeCount += 1
            totalQuantity += trade.quantity
            totalPrice += trade.price
            totalPrice2 += pow(Double(trade.price),2)
            data.append([trade.buyer.price,trade.seller.price])
        }
        averagePrice = Double(totalPrice) / Double(totalQuantity)
        stdev = sqrt((Double(totalPrice2) - Double(totalQuantity) * pow(averagePrice,2)) / (Double(totalQuantity - 1)))
        endTime = DispatchTime.now()
        elapsedTime = (Double(self.endTime.uptimeNanoseconds) - Double(self.startTime.uptimeNanoseconds)) / 1_000_000_000
        message = "Total Trades: \(tradeCount) \n"
        message.append("Average Price: \(((averagePrice*100).rounded()/100)) \n")
        message.append("Stdev: \((stdev * 100).rounded()/100) \n")
        message.append("Elapsed time: \((self.elapsedTime * 100).rounded()/100) seconds. \n")
        print("End CalcStats \(Date.now)")
    }
    func updateGraph() {
        graphData = GraphData()
        for buyer in market.buyers.filter({$0.quantityHeld>0}) {
                graphData.updateValue(value: 1, forKey: buyer.price, cat: "Bid")
        }
            
        for seller in market.sellers.filter({$0.quantityHeld==0}) {
                graphData.updateValue(value: 1, forKey: seller.price, cat: "Ask")
        }
        for trade in market.trades {
            graphData.updateValue(value: trade.quantity, forKey: trade.price, cat: "Actual")
        }
        self.objectWillChange.send()
    }

    func Run() async -> Void {
        
        market.clearData()
        isRunning = true
        startTime = DispatchTime.now()
                
        initAgents()
        
        doTrades()
        updateGraph()
        calculateStats()
        
        isRunning = false
        
        objectWillChange.send()
    }
}
