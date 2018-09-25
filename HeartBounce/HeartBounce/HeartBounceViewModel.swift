//
//  HeartBounceViewModel.swift
//  HeartBounce
//
//  Created by 안덕환 on 23/09/2018.
//  Copyright © 2018 thekan. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

class HeartBounceViewModel {
    
    enum ViewAction {
        case createFinger(Finger)
        case updateFingerPositions
        case leaveFinger(Finger)
    }
    
    enum State {
        case idle
        case wait
        case progress
        case ended
    }
    
    let viewAction = PublishSubject<ViewAction>()
    let fingers = Variable<[Finger]>([])
    let state = Variable<State>(.idle)
    let fingerProducer = FingerProducer()
    let disposeBag = DisposeBag()
    let timer = CountDownTimer(from: 5, to: 0)
    
    var numberOfFingers: Int {
        return fingers.value.count
    }
    
    var numberOfLeavedFingers: Int {
        return fingers.value.filter { $0.isLeaved }.count
    }
    
    var numberOfUnleavedFingers: Int {
        return fingers.value.filter { !$0.isLeaved }.count
    }
    
    init() {
        timer.countDown
            .subscribe(onNext: { [weak self] count in
                guard let `self` = self else {
                    return
                }
                guard self.state.value == .wait else {
                    return
                }
                if count == 0 {
                    print("started")
                    self.state.value = .progress
                }
            }).disposed(by: disposeBag)
    }
    
    func fingerForIdentifier(_ identifier: String) -> Finger? {
        guard let finger = fingers.value.first(where: { $0.identifier == identifier }) else {
            return nil
        }
        return finger
    }
    
    func requestAppendFinger(at pointt: CGPoint, with identifier: String) {
        if state.value == .idle {
            state.value = .wait
        }
        
        guard state.value == .wait else {
            return
        }
        guard !fingers.value.contains(where: { $0.identifier == identifier }) else {
            return
        }
        
        let finger = fingerProducer.produce(identifier: identifier, point: pointt)
        fingers.value.append(finger)
        viewAction.onNext(.createFinger(finger))
        timer.count()
    }
    
    func requestUpdateFinger(at point: CGPoint, with identifier: String) {
        guard let fingerIndex = fingers.value.firstIndex(where: { $0.identifier == identifier }) else {
            return
        }
        fingers.value[fingerIndex].currentPoint = point
        viewAction.onNext(.updateFingerPositions)
    }
    
    func leaveFinger(with identifier: String) {
        guard let leavedFingernIndex = fingers.value.firstIndex(where: { $0.identifier == identifier }) else {
            return
        }
        
        fingers.value[leavedFingernIndex].isLeaved = true
        let leavedFinger = fingers.value[leavedFingernIndex]
        viewAction.onNext(.leaveFinger(leavedFinger))
        
        if fingers.value.count <= 1 {
            state.value = .ended
        }
    }
}
