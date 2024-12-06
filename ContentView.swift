//
//  ContentView.swift
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
import Charts

struct ContentView: View {
    @StateObject var sim = Sim()
    var body: some View {
        
        VStack {
            HStack {
                VStack {
                    LabeledContent {
                        TextField("Buyers", value: $sim.market.numBuyers, format: .number).keyboardType(.decimalPad)
                    } label: { 
                        Text("Num Buyers:")
                    }
                    LabeledContent {
                        TextField("Max Buyer Value", value: $sim.market.maxBuyerValue, format: .number).keyboardType(.decimalPad)
                    } label: {
                        Text("Max Buyer Value:")
                    }
                    
                    LabeledContent {
                        TextField("Sellers", value: $sim.market.numSellers, format: .number).keyboardType(.decimalPad)
                    } label: {
                        Text("Num Sellers:")
                    }
                    LabeledContent {
                        TextField("Max Seller Value", value: $sim.market.maxSellerValue, format: .number).keyboardType(.decimalPad)
                    } label: {
                        Text("Max Seller Value:")
                    }
                    
                    LabeledContent {
                        TextField("MaxTrades", value: $sim.market.maxTrades, format: .number).keyboardType(.decimalPad)
                    } label: { 
                        Text("Max Trades:")
                    }
                }.padding().padding(.horizontal).padding(.horizontal).padding(.horizontal)
                VStack {
                    Text("\($sim.message.wrappedValue)")
                }
            }
            HStack {
                Button("Reset", action: {
                    sim.reset()
                    sim.objectWillChange.send()
                }).buttonStyle(.bordered)
                Button {
                    Task {
                        await sim.Run()
                    }
                    sim.objectWillChange.send()
                } label: {
                    Label("Run", systemImage: "clock")
                }
                .buttonStyle(.bordered)
                .disabled({sim.isRunning}())
                .symbolEffect(.bounce, value:{sim.isRunning}())
            }.padding()
           
            Chart(sim.graphData.data.sorted(by:{$0.value<$1.value})) {
                LineMark(
                    x: .value("x", $0.value),
                    y: .value("y", $0.key),
                    series: .value("cat", $0.cat)
                ).foregroundStyle(by: .value("cat", $0.cat))
            }
            .frame(minHeight: 100)
            .chartLegend(position: .top, alignment: .center)
            .chartXAxisLabel("Quantity", alignment: .center)
            .chartYAxisLabel("Price", position: .leading)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            
        }
        
    }
}
