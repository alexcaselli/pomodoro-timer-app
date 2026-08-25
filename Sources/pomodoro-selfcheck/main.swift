import Foundation
import PomodoroCore

let status = await AppEntry.selfCheck()
exit(status)
