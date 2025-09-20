#set text(font: "Times New Roman")

// Константы
#let START-PAGE = 2
#let MARGIN = (left: 30mm, right: 15mm, top: 20mm, bottom: 20mm)
#let TEXT-SIZE = 14pt
#let LISTING-ERROR-PAGINATION = 0.24em // подобрано для размера шрифта от 13 до 18pt вкл.
#let INDENT = 1.25cm
#let LANG = "ru"
#let HYPHENATE = false
#let JUSTIFY = true
#let SPACING = 1.05em
#let PAR-LEADING = SPACING
#let PAGE-NUMBERING = "1"
#let LONG-DASH = [---]
#let LIST-DOT = [.]
#let leading = 1.5em
#let LEADING = leading - 0.75em // Normalization
#let LIST-INDENT = 0.25cm

// Настройка страницы
#set page(
  // Отступы от краев страницы
  margin: MARGIN,
  // Нумерация на страницах
  numbering: PAGE-NUMBERING
)

// Настройка текста
#set text(
  size: TEXT-SIZE,
  lang: LANG,
  hyphenate: HYPHENATE
)

// Настройка абзацев
#set par(
  justify: JUSTIFY,
  first-line-indent: (
    amount: INDENT,
    all: true
  ),
  spacing: SPACING,
  leading: PAR-LEADING
)

// Содержание
#set outline(indent: INDENT, depth: 3, title: text(size: TEXT-SIZE, upper[содержание]))

#show outline: set block(below: INDENT / 2)
#show outline.entry: it => {
  show linebreak: [ ]
  it
}

#show outline: set align(center)


// Ссылки через @
#set ref(supplement: none)
#set figure.caption(separator: " — ")

// Нумерация математических формул
#set math.equation(numbering: "(1)")

#show image: set align(center)
#show figure.where(kind: image): set figure(supplement: [Рисунок])

#show figure.where(
  kind: table
): it => {
  set block(breakable: true)
  set figure.caption(position: top)
  it
}
#show figure.caption.where(kind: table): set align(left)
#show table.cell: set align(left)

// Списки (ненумерованный и нумерованный)
#show list: it => {
  set par(justify: true, first-line-indent: (
    amount: INDENT,
    all: true
  ))
  
  let counter = 0
  for item in it.children {
    if counter == 0 {
      [---#h(LIST-INDENT)#item.body]
    } else {
      [#h(INDENT)---#h(LIST-INDENT)#item.body]
    }
    [\ ]
    counter += 1
  }
}
#show enum: it => {
  set par(justify: true, first-line-indent: (
    amount: INDENT,
    all: true
  ))
  
  let counter = 0
  for item in it.children {
    if counter == 0 {
      [#(counter + 1)#LIST-DOT#h(LIST-INDENT)#item.body]
    } else {
      [#h(INDENT)#(counter + 1)#LIST-DOT#h(LIST-INDENT)#item.body]
    }
    [\ ]
    counter = counter + 1
  }
}

// Заголовки
#set heading(numbering: "1.1.1.")

#show heading: set text(size: TEXT-SIZE)

#let structural-heading-titles = (
  performers: [СПИСОК ИСПОЛНИТЕЛЕЙ],
  abstract: [РЕФЕРАТ],
  terms: [ТЕРМИНЫ И ОПРЕДЕЛЕНИЯ],
  abbreviations: [ПЕРЕЧЕНЬ СОКРАЩЕНИЙ И ОБОЗНАЧЕНИЙ],
  intro: [ВВЕДЕНИЕ],
  conclusion: [ЗАКЛЮЧЕНИЕ],
  references: [СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ]
)

#let structure-heading-style = it => {
  align(center)[#upper(it)]
}

#let structure-heading(body) = {
  structure-heading-style(heading(numbering: none)[#body])
}

#let headings(text-size, indent, pagebreaks) = body => {
  show heading: set text(size: text-size)
  set heading(numbering: "1.1.1.")
  
  show heading: it => {
    if it.body not in structural-heading-titles.values() {
      pad(it, left: indent)
    } else {
      it
    }
  }
  
  show heading.where(level: 1): it => {
    if pagebreaks {
      pagebreak(weak: true)
    }
    it
  }
  
  let structural-heading = structural-heading-titles
    .values()
    .fold(selector, (acc, i) => acc.or(heading.where(body: i, level: 1)))
  
  show structural-heading: set heading(numbering: none)
  show structural-heading: it => {
    if pagebreaks {
      pagebreak(weak: true)
    }
    structure-heading-style(it)
  }
  body
}
#show heading.where(level: 1): set block(above: PAR-LEADING, below: PAR-LEADING)
#show heading.where(level: 2): set block(above: PAR-LEADING, below: PAR-LEADING)
#show heading.where(level: 3): set block(above: PAR-LEADING, below: PAR-LEADING)

#show: headings(TEXT-SIZE, INDENT, true)

// Листинг
#let listing-counter = counter("listing")

#let listing(title, code-content) = {
  // Увеличиваем счетчик листингов
  listing-counter.step()
  
  context {
    // Получаем номер текущего листинга
    let listing-num = listing-counter.get().first()
    
    // Разбиваем код на строки
    let code-lines = code-content.text.split("\n")
    
    // Функция для создания таблицы с кодом
    let create-listing-table(lines, is-continuation: false) = {
      let caption-text = if is-continuation {
        [Продолжение листинга #listing-num]
      } else {
        [Листинг #listing-num --- #title]
      }
      
      figure(
        table(
          columns: 1fr,
          stroke: 0.5pt,
          
          // Содержимое таблицы
          block(
            width: 100%,
            {
              set text(size: TEXT-SIZE)
              set par(leading: LEADING)
              
              // Соединяем строки обратно
              raw(lines)
            },
          )
        ),
        supplement: none,
        caption: caption-text
      )
    }
    
    // Вычисляем количество строк, которое помещается на странице
    layout(size => {
      // Разбиваем код на страницы
      let pages = ()
      let current-page = ()
      let start_y = here().position().y
      // Измеряем высоту одной строки
      let line-height = measure(
        block(height: TEXT-SIZE + LISTING-ERROR-PAGINATION)[Тестовый текст]
      ).height
      // Вычисляем примерное количество строк на странице
      let available-height = size.height - start_y
      let lines-per-page = calc.max(1, calc.floor(available-height / line-height)) + 2
      let is-continious = false
      for line in code-lines {
        current-page.push(line)
        
        if current-page.len() >= lines-per-page {
          pages.push(current-page)
          if pages.len() > 1 {
            is-continious = true
          }
          create-listing-table(current-page.join("\n"), is-continuation: is-continious)
          
          current-page = ()
          start_y = 0pt
          
          available-height = size.height - start_y
          lines-per-page = calc.max(1, calc.floor(available-height / line-height))
        }
      }
      
      // Добавляем последнюю страницу, если она не пустая
      if current-page.len() > 0 {
        pages.push(current-page)
        if pages.len() == 1 {
          is-continious = false
        } else {
          is-continious = true
        }
        create-listing-table(current-page.join("\n"), is-continuation: is-continious)
      }
    })
  }
}

#context(counter(page).update(START-PAGE))