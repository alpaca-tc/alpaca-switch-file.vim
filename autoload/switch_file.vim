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

let s:default_context = {
      \ "basename": function('fnamemodify', [expand('%:p'), ':t']),
      \ "basename_no_ext": function('fnamemodify', [expand('%:p'), ':t:r:r:r:r']),
      \ }

function! s:current_context()
  if exists('b:switch_file_context')
    return extend(copy(b:switch_file_context), s:default_context)
  elseif exists('g:switch_file_context')
    return extend(copy(g:switch_file_context), s:default_context)
  else
    return s:default_context
  endif
endfunction

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
  let context = s:resolve_context(s:current_context())
  let target = ''

  for rule in rules
    for index in range(0, len(rule) - 1)
      let pattern = substitute(rule[index], '%', '\\(.*\\)', '')

      if match(path, pattern) >= 0
        let candidates = []

        for length in range(1, len(rule))
          let raw_replacement = rule[(index + (length * a:direction) + len(rule)) % len(rule)]
          let replacement = s:build_replacement(raw_replacement, context)
          let candidate = substitute(path, pattern, replacement, '')

          if path != candidate
            call add(candidates, candidate)
          endif

          let files = split(glob(candidate))

          for i in range(0, len(files) - 1)
            if path != files[i]
              call add(candidates, files[i])
            endif
          endfor
          " call add(candidates, substitute(fnamemodify(path, ':t'), pattern, replacement, ''))
        endfor

        for candidate in candidates
          if filereadable(candidate)
            edit `=candidate`
            return
          endif
        endfor
      end
    endfor
  endfor
endfunction

function! s:resolve_context(context)
  let context = {}

  if type(a:context) == type({})
    for key in keys(a:context)
      let resolved = v:false
      let value = v:null

      if type(a:context[key]) == type("")
        let value = function(key)()
      elseif type(a:context[key]) == type(function("tr"))
        let value = a:context[key]()
      endif

      if type(value) == type("")
        let context[key] = value
      endif
    endfor
  endif

  return context
endfunction

function! s:build_replacement(replacement, context)
  let replacement = a:replacement
  let count = 1
  let replacement = substitute(replacement, '%', '\\1', '')

  for key in keys(a:context)
    let replacement = substitute(replacement, ':' . key, a:context[key], '')
  endfor

  return replacement
endfunction
