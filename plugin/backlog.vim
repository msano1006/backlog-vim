scriptencoding utf-8

let space_id = ''
let user = ''

let s:auth = 'basic '.webapi#base64#b64encode(user)
let s:url = 'https://'.space_id.'.backlog.jp/XML-RPC'
let s:open_prefix = '+ '
let s:close_prefix = '- '

" Common Init
function! InitCommon()
  setlocal nowrap
  setlocal nonu
endfunction

function! CreateBuffer()
  let winnum = bufwinnr(bufnr('==Backlog=='))
  if winnum != -1
      if winnum != bufwinnr('%')
          exe "normal \<c-w>".winnum."w"
      endif
  else
      exec 'silent 30vsplit ==Backlog=='
  endif
  call InitCommon()
endfunction

" is Array in Value
function! IsExist(value, array)
  for i in a:array
    if i == a:value
      return 1
    endif
  endfo
  return 0
endfunction

" display underline
function! Link2Underline()
  syntax match UnderLineLink '^+ .\+$' display containedin=ALL
  hi UnderLineLink term=underline cterm=underline ctermbg=NONE guibg=NONE
endf

" set event
function! SetEvent()
  noremap <silent> <buffer> <Space> :call ProjectsToggle()<CR>
  noremap <silent> <buffer> q :call CloseBuffer()<CR>
endfunction
" test event
function! ProjectsToggle()
  let current_line = getline('.')
  let current_line_num = line('.')
  if current_line =~ '^'. s:open_prefix .'.\+$'
    let key_name = substitute(current_line, s:open_prefix, '', '')
    call setline(current_line_num, s:close_prefix . key_name) 
    call append(current_line_num, s:projects[key_name]['name'])
  elseif current_line =~ '^'. s:close_prefix .'.\+$'
    call setline(current_line_num, s:open_prefix.substitute(current_line, s:close_prefix, '', '')) 
    exec printf('%d,%dd', current_line_num + 1, current_line_num + 1)
    if current_line_num != line('$')
      call cursor(current_line_num, '.')
    endif
  endif
endfunction
" test event
function! CloseBuffer()
  exec 'q!'
endfunction

"Connection Bucklog API
function! Connect(data)
  let res = webapi#http#post(s:url, a:data, { "Content-Type": "text/xml", "Authorization": s:auth })
  return webapi#xml#parse(res.content)
endfunction

let s:projects = {} 

"GetProjects
function! GetProjects(...)
  let data = ''
  \.'<methodCall>'
  \.' <methodName>backlog.getProjects</methodName>'
  \.' <params>'    
  \.' </params>'
  \.'</methodCall>'
  let dom = Connect(data)
  let s:projects = {} 
  let project_keys = [] 
  for j in dom.findAll('struct')
    let dict = {}
    for i in j.findAll('member')
      let name = i.find('name').value()
      if IsExist(name, ['key']) == 1 
        call add(project_keys, s:open_prefix . i.find('value').value())
        let dict[name] = i.find('value').value() 
      endif
      if IsExist(name, ['url', 'name', 'id']) == 1 
        let dict[name] = i.find('value').value() 
      endif
    endfor
    let s:projects[dict['key']] = dict
  endfor
  call CreateBuffer()
  call setline(1, project_keys)
  call Link2Underline()
  call SetEvent()
  echo s:projects
endfunction
command! GetProjects call GetProjects(<q-args>)

"GetIssues
function! GetIssues(...)
  let pid = a:1 
  let data = ''
  \.'<methodCall>'
  \.'  <methodName>backlog.findIssue</methodName>'
  \.'  <params>'
  \.'    <param>'
  \.'      <value>'
  \.'        <struct>'
  \.'          <member>'
  \.'            <name>projectId</name>'
  \.'            <value>'
  \.'              <int>'.pid.'</int>'
  \.'            </value>'
  \.'          </member>'
  \.'          <member>'
  \.'            <name>limit</name>'
  \.'            <value>'
  \.'              <int>100</int>'
  \.'            </value>'
  \.'          </member>'
  \.'        </struct>'
  \.'      </value>'
  \.'    </param>'
  \.'  </params>'
  \.'</methodCall>'
  echo data
  let dom = Connect(data)
  let dict = {}
  for i in dom.findAll('member')
    let dict[i.find('name').value()] = i.find('value').toString()
  endfor
  echo dict
endfunction
command! -nargs=+ GetIssues call GetIssues(<q-args>)

"GetIssue
function! GetIssue(...)
  let tid = a:1 
  let data = ''
  \.'<methodCall>'
  \.' <methodName>backlog.getIssue</methodName>'
  \.' <params>'    
  \.'   <param>'
  \.'     <value>'
  \.'       <string>'.tid.'</string>'
  \.'     </value>'
  \.'   </param>'
  \.' </params>'
  \.'</methodCall>'
  let dom = Connect(data)
  let dict = {}
  for i in dom.findAll('member')
    let dict[i.find('name').value()] = i.find('value').toString()
  endfor
  echo dict
endfunction
command! -nargs=+ GetIssue call GetIssue(<q-args>)
