//
//  HXPHPicker.swift
//  照片选择器-Swift
//
//  Created by Silence on 2020/11/9.
//  Copyright © 2020 Silence. All rights reserved.
//

class HXPHPicker {}

/*
 无论, 是子类化, 还是使用分类, 都是使用类暴露出的 Public 来进行的扩展.
 hx 这种, Wrapper 的方式, 是将对象传递到 base 里面, 然后, 将对于 base 的修改, 放到 hx 的作用域范围内.
 这种方式, 使得对于 base 的功能扩展, 能够限制在了 hx 的范围呢, 而扩展, 还是使用 base 类暴露的 Public 行为.
 Base 的不同, 增加不同的扩展, 就相当于是, Base 类增加了不同的分类. 
 */

public struct HXPickerWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol HXPickerCompatible: AnyObject { }

public protocol HXPickerCompatibleValue {}

extension HXPickerCompatible {
    public var hx: HXPickerWrapper<Self> {
        get { return HXPickerWrapper(self) }
        set { } // swiftlint:disable:this unused_setter_value
    }
}

extension HXPickerCompatibleValue {
    public var hx: HXPickerWrapper<Self> {
        get { return HXPickerWrapper(self) }
        set { } // swiftlint:disable:this unused_setter_value
    }
}
