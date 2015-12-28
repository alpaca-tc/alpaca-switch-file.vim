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

function! s:move(direction) "{{{
  let path = expand('%:p')
  let rules = s:current_rules()
  let target = ''

ruby <<EOS
  direction = VIM.evaluate('a:direction')
  path = VIM.evaluate('path')
  rule_list = VIM.evaluate('rules')

  rule_list.each do |rules|
    rules.each_with_index do |rule, index|
      regexp = Regexp.new(rule.sub('%', '(.*)'))

      if path =~ regexp
        matched = Regexp.last_match[1]
        base = path.gsub(regexp, '')
        replaced = rules[(index + direction) % rules.length].gsub(/\\./, '.').sub('%', matched)
        VIM.command("let target = '#{base + replaced}'")
      end
    end
  end
EOS

  echo target
  if !empty(target) && filereadable(target)
    edit `=target`
  endif
endfunction "}}}
