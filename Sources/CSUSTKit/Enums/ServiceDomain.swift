public enum ServiceDomain {
    case authServer
    case ehall
    case mooc
    case education
    case campusCard
    case eval
    case physicsExperiment
    case chaoxing
    case chaoxingAPI
}

extension ServiceDomain {
    var scheme: String {
        switch self {
        case .authServer, .ehall, .campusCard, .eval, .chaoxing, .chaoxingAPI:
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
        case .eval:
            return "zbxt.csust.edu.cn"
        case .physicsExperiment:
            return "10.255.65.52"
        case .chaoxing:
            return "i.mooc.chaoxing.com"
        case .chaoxingAPI:
            return "mooc1-api.chaoxing.com"
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
        case .eval:
            return "e3e5295206d19ea6a84a70370bb4a4db1c0176decbcfae350b6673a608d0d751"
        case .physicsExperiment:
            return "ee536efb7808aac9b0bc36403333c380"
        case .chaoxing:
            return "05cc0efef664f2f86e16be7e169783e378f442c81ff65a9b669a92968c03bb85"
        case .chaoxingAPI:
            return "d529fd82bb238cec8e955f0dcc78df9c9c3b68d58d3df59d4c7d1ec8318c66d6"
        }
    }
}
