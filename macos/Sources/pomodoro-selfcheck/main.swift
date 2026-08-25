import Foundation
import PomodoroCore

// `--render <path>` writes a PNG of the main view instead of running the assertions.
if let i = CommandLine.arguments.firstIndex(of: "--render"),
   i + 1 < CommandLine.arguments.count {
    let path = CommandLine.arguments[i + 1]
    let ok = AppEntry.renderPreview(to: path)
    print(ok ? "rendered \(path)" : "render failed")
    exit(ok ? 0 : 1)
}

let status = await AppEntry.selfCheck()
exit(status)
