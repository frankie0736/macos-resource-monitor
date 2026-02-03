import SwiftUI

struct DateInfoView: View {
    @State private var currentDate = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 2) {
            Divider()
                .background(Color.matrixDarkGreen.opacity(0.3))

            HStack(spacing: 0) {
                // Weekday
                Text(weekdayString)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.matrixGreen)

                Text(" · ")
                    .foregroundColor(Color.matrixDarkGreen)

                // Solar date
                Text(solarDateString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Color.matrixGreen.opacity(0.8))

                Text(" · ")
                    .foregroundColor(Color.matrixDarkGreen)

                // Lunar date
                Text(lunarDateString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange)
            }
            .padding(.vertical, 4)
        }
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }

    private var weekdayString: String {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate)
        return weekdays[weekday - 1]
    }

    private var solarDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currentDate)
    }

    private var lunarDateString: String {
        let chineseCalendar = Calendar(identifier: .chinese)

        let month = chineseCalendar.component(.month, from: currentDate)
        let day = chineseCalendar.component(.day, from: currentDate)

        let monthNames = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]
        let dayNames = [
            "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
            "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
            "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
        ]

        let monthStr = monthNames[month - 1] + "月"
        let dayStr = day <= 30 ? dayNames[day - 1] : "三十"

        return monthStr + dayStr
    }
}

#Preview {
    DateInfoView()
        .background(Color.matrixBg)
}
