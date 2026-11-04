import Alamofire
import CSUSTKit

@main
struct Main {
    static func main() async {
        let session = Session()
        let app = ExampleApp(session: session)
        await app.run()
        print("程序已退出。")
    }
}
