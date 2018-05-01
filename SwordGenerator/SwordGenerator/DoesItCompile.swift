//
//  DoesItCompile.swift
//  SwordGenerator
//
//  Created by Andrew Pleshkov on 30/04/2018.
//  Copyright © 2018 test. All rights reserved.
//

import Foundation

class CountryContainer {
    
    let omg: Int?
    let foo: Foo
    let bar: Bar
    let baz: Baz
    let quux2Provider: QuuxProvider
    
    init(code: String, omg: Int?) {
        let foo = Foo(code: code)
        let bar = Bar(foo)
        var baz = Baz()
        let quux2Provider = QuuxProvider()
        
        baz.bar = bar
        quux2Provider.foo = foo
        
        self.omg = omg
        self.foo = foo
        self.bar = bar
        self.baz = baz
        self.quux2Provider = quux2Provider
    }
}

extension CountryContainer {
    
    var quux1: Quux {
        let quux1 = Quux(foo: foo)
        return quux1
    }
    
    var quux2: Quux {
        return quux2Provider.get()
    }
    
    var quux3: Quux {
        let quux3Provider = QuuxProvider()
        return quux3Provider.get()
    }
}

// MARK

class Foo {
    
    let code: String
    
    init(code: String) {
        self.code = code
    }
}

class Bar {
    
    init(_ foo: Foo) {}
}

struct Baz {
    
    var bar: Bar? = nil
    
    init() {}
}

class Quux {
    
    init(foo: Foo) {}
}

class QuuxProvider {
    
    var foo: Foo? = nil
    
    func get() -> Quux! {
        return nil
    }
}
