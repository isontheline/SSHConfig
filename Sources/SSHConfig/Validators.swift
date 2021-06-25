//
//  File.swift
//  
//
//  Created by Yury Korolev on 24.06.2021.
//

import Foundation

struct Validators {
  var yesnos = Set<String>([
    "BatchMode",
    "CanonicalizeFallbackLocal",
    "ChallengeResponseAuthentication",
    "CheckHostIP",
    "ClearAllForwardings",
    "Compression",
    "EnableSSHKeysign",
    "ExitOnForwardFailure",
    "ForwardAgent",
    "ForwardX11",
    "ForwardX11Trusted",
    "GatewayPorts",
    "GSSAPIAuthentication",
    "GSSAPIDelegateCredentials",
    "HostbasedAuthentication",
    "IdentitiesOnly",
    "KbdInteractiveAuthentication",
    "NoHostAuthenticationForLocalhost",
    "PasswordAuthentication",
    "PermitLocalCommand",
    "PubkeyAuthentication",
    "RhostsRSAAuthentication",
    "RSAAuthentication",
    "StreamLocalBindUnlink",
    "TCPKeepAlive",
    "UseKeychain",
    "UsePrivilegedPort",
    "VisualHostKey",
  ].map { $0.lowercased() })
  
  var uints = Set([
    "CanonicalizeMaxDots",
    "CompressionLevel",
    "ConnectionAttempts",
    "ConnectTimeout",
    "NumberOfPasswordPrompts",
    "Port",
    "ServerAliveCountMax",
    "ServerAliveInterval"
  ].map { $0.lowercased() })
  
  func mustBeYesOrNo(_ lkey: String) -> Bool {
    yesnos.contains(lkey)
  }

  func mustBeUint(_ lkey: String) -> Bool {
    uints.contains(lkey)
  }

  func validate(key: String, val: String) throws {
    let lkey = key.lowercased()
    if mustBeYesOrNo(lkey) && (val != "yes" && val != "no") {
      throw SSHConfig.Err.mustBeYesOrNo(key: key, value: val)
    }
    if mustBeUint(lkey) && UInt(val) == nil {
      throw SSHConfig.Err.mustBeUInt(key: key, value: val)
    }
  }

  let pluralDirectives = Set(
    [
      "CertificateFile",
      "IdentityFile",
      "DynamicForward",
      "RemoteForward",
      "SendEnv",
      "SetEnv"
    ].map { $0.lowercased() }
  )
}
