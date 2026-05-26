public enum ServiceDomain {
    case authServer
    case ehall
    case mooc
    case education
    case campusCard
    case physicsExperiment
}

extension ServiceDomain {
    var scheme: String {
        switch self {
        case .authServer, .ehall, .campusCard:
            return "https"
        case .mooc, .education, .physicsExperiment:
            return "http"
        }
    }

    var directHost: String {
        switch self {
        case .authServer:
            return "authserver.csust.edu.cn"
        case .ehall:
            return "ehall.csust.edu.cn"
        case .mooc:
            return "pt.csust.edu.cn"
        case .education:
            return "xk.csust.edu.cn"
        case .campusCard:
            return "hxyxh5.csust.edu.cn"
        case .physicsExperiment:
            return "10.255.65.52"
        }
    }

    var vpnHex: String {
        switch self {
        case .authServer:
            return "b9fbab94ec37584ef499d74673ec2c940949105c7b30eca147702d9482299f99"
        case .ehall:
            return "1e2b5c384f0dc42e4d0db781d590f8e2f8f129ae812718586ddba3948db7b103"
        case .mooc:
            return "ca1e69080fcc45ac45bed760950fd677"
        case .education:
            return "505c0e70383db2ebb7035169513d1ffa"
        case .campusCard:
            return "6a312b2d860191c92db8c011e7e418eac2691c647e6e2b00de67552d70884967"
        case .physicsExperiment:
            return "ee536efb7808aac9b0bc36403333c380"
        }
    }
}
