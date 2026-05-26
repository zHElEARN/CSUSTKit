extension CampusCardHelper {
    /// 楼栋
    public struct Building: BaseModel {
        /// 楼栋名称
        public let name: String
        /// 楼栋ID
        public let id: String
        /// 所属校区
        public let campus: Campus

        public init(name: String, id: String, campus: Campus) {
            self.name = name
            self.id = id
            self.campus = campus
        }
    }
}
