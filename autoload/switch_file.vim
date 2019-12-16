function! switch_file#next() "{{{
  call s:move(1)
endfunction "}}}

function! switch_file#prev() "{{{
  call s:move(-1)
endfunction "}}}

function! s:current_rules() "{{{
  if exists('b:switch_file_rules')
    return b:switch_file_rules
  elseif exists('g:switch_file_rules') && !empty(s:current_rule_from_filetype())
    return s:current_rule_from_filetype()
  else
    return [[]]
  endif
endfunction "}}}

function! s:current_rule_from_filetype()
  let result = []
  let filetype = ''

  for part in split(&filetype, '\.')
    if has_key(g:switch_file_rules, part)
      call extend(result, g:switch_file_rules[part])
    endif
  endfor

  return result
endfunction

function! s:move(direction)
  let path = expand('%:p')
  let rules = s:current_rules()
  let target = ''

  for rule in rules
    for index in range(0, len(rule) - 1)
      let pattern = substitute(rule[index], '%', '\\(.*\\)', 'g')

      if match(path, pattern) >= 0
        let raw_replacement = rule[(index + a:direction) % len(rule)]
        let replacement = s:build_replacement(raw_replacement)
        let new_path = substitute(path, pattern, replacement, 'g')

        if filereadable(new_path)
          edit `=new_path`
          return
        endif
      end
    endfor
  endfor
endfunction

function! s:build_replacement(replacement)
  let replacement = a:replacement
  let count = 1
  let replacement = substitute(replacement, '%', '\\' . count, '')

  return replacement
endfunction

