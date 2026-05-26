extension CampusCardHelper {
    /// 宿舍
    public struct Room: BaseModel {
        /// 宿舍名称
        public let name: String
        /// 宿舍ID
        public let id: String
        /// 所属楼栋
        public let building: Building

        public init(name: String, id: String, building: Building) {
            self.name = name
            self.id = id
            self.building = building
        }
    }
}
