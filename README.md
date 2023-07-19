# WHSheetViewController

iOS14以上対応
シートヴュー作成lib

mapMode追加 (pullMiniEnable, pullMaxDisable, 別場所のtouchEvent生き, 別場所への画像フィルターかけない)
```
useMapMode(_ check: Bool) = true
```
で mapMode(他のflagもひきづられる可能性あり)
 
fullScreen で表示の時に、closeFillButtonを表示追加
```
closeFillButtonOn = true
```
で closeFillButtonを表示

```
WHOptions(useInlineMode: true)
```
の時はinline (view + subViewの状態)なので
```
sheetVC.animateIn(to: self.view, in: self)
```
to は subViewへ、inは元のviewから
という意味

```
WHOptions(useInlineMode: false)
```
の時はModalの状態 (別viewで dismissで閉じる)なので
```
present(sheet, animated: true)
```
animated: trueすると後ろのviewが 標準modalの時と同じで少し小さくなる(animated: falseだとanimationしない代わりにサイズ変更はなし)