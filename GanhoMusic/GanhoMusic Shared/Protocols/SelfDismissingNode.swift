//
//  SelfDismissingNode.swift
//  GanhoMusic Shared
//
//  Phase 4-R · 자가 소멸 노드 마커 protocol — Rule of three 추출
//

import SpriteKit

/// 자가 소멸 노드 마커 프로토콜.
/// 4-3 AirplaneNode부터 4-5 BombFlashNode까지 등장한 fire-and-forget 패턴
/// (SKAction.sequence 마지막 단계가 .removeFromParent())의 *역할 분류*.
/// 채택 노드는 SKNode 또는 그 자손이어야 한다(class-constrained).
/// 본 protocol은 *비어 있는 marker* — 미래 protocol extension으로 *공통 동작*을 추가 가능.
///
/// 채택 노드 (Phase 4-R 시점):
/// - AirplaneNode: crossScreen(sceneWidth:atY:) — Phase 4-3
/// - AirforceOverlayNode: showAndDismiss() — Phase 4-4
/// - BombFlashNode: flash(sceneSize:) — Phase 4-5
protocol SelfDismissingNode: SKNode {}
