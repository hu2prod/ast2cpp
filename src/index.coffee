require 'fy/codegen'

module = @
# @default_value_from_type =
#   'int'   : "0"
#   'float' : "0.0"
#   'string': "''"
#   'array' : "[]"
#   'hash'  : "{}"
# @need_constructor_reset =
#   'array' : true
#   'hash' : true
# 
@bin_op_name_map =
  ADD : '+'
#   SUB : '-'
#   MUL : '*'
#   DIV : '/'
#   DIV_INT : '//'
#   MOD : '%'
#   POW : '**'
#   
#   BIT_AND : '&'
#   BIT_OR  : '|'
#   BIT_XOR : '^'
#   
#   BOOL_AND : '&&'
#   BOOL_OR  : '||'
#   # BOOL_XOR : '^'
#   
#   SHR : '>>'
#   SHL : '<<'
#   LSR : '>>>' # логический сдвиг вправо >>>
#   
#   ASSIGN : '='
#   ASS_ADD : '+='
#   ASS_SUB : '-='
#   ASS_MUL : '*='
#   ASS_DIV : '/='
#   ASS_DIV_INT : '//='
#   ASS_MOD : '%='
#   ASS_POW : '**='
#   
#   ASS_SHR : '>>='
#   ASS_SHL : '<<='
#   ASS_LSR : '>>>=' # логический сдвиг вправо >>>
#   
#   ASS_BIT_AND : '&='
#   ASS_BIT_OR  : '|='
#   ASS_BIT_XOR : '^='
#   
#   # ASS_BOOL_AND : ''
#   # ASS_BOOL_OR  : ''
#   # ASS_BOOL_XOR : ''
#   
#   EQ : '=='
#   NE : '!='
#   GT : '>'
#   LT : '<'
#   GTE: '>='
#   LTE: '<='
# 
@bin_op_name_cb_map =
#   BOOL_XOR      : (a, b)->"(#{a} ^ #{b})"
#   ASS_BOOL_AND  : (a, b)->"(#{a} = !!(#{a} & #{b}))"
#   ASS_BOOL_OR   : (a, b)->"(#{a} = !!(#{a} | #{b}))"
#   ASS_BOOL_XOR  : (a, b)->"(#{a} = !!(#{a} ^ #{b}))"
  INDEX_ACCESS  : (a, b)->"(#{a})[#{b}]"
  
@un_op_name_cb_map =
  INC_RET : (a)->"++(#{a})"
  RET_INC : (a)->"(#{a})++"
  DEC_RET : (a)->"--(#{a})"
  RET_DEC : (a)->"(#{a})--"
  # BOOL_NOT: (a)->"!(#{a})"
  BIT_NOT : (a)->"~(#{a})"
  MINUS   : (a)->"-(#{a})"
  PLUS    : (a)->"+(#{a})"

class @Gen_context
  expand_hash : false
  in_class : false
  mk_nest : ()->
    t = new module.Gen_context
    t

@gen = gen = (ast, opt = {}, ctx = new module.Gen_context)->
  switch ast.constructor.name
    # ###################################################################################################
    #    expr
    # ###################################################################################################
    when "Const"
      switch ast.type.main
        when 'bool', 'int', 'float'
          ast.val
        when 'string'
          JSON.stringify ast.val
    
    # when "Array_init"
    #   jl = []
    #   for v in ast.list
    #     jl.push gen v, opt, ctx
    #   "[#{jl.join ', '}]"
    # 
    # when "Hash_init", "Struct_init"
    #   jl = []
    #   for k,v of ast.hash
    #     jl.push "#{JSON.stringify k}: #{gen v, opt, ctx}"
    #   if ctx.expand_hash
    #     if jl.length == 0
    #       "{}"
    #     else
    #       """
    #       {
    #         #{join_list jl, '  '}
    #       }
    #       """
    #   else
    #     "{#{jl.join ', '}}"
    # 
    when "Var"
      ast.name
    
    when "Bin_op"
      _a = gen ast.a, opt, ctx
      _b = gen ast.b, opt, ctx
      if op = module.bin_op_name_map[ast.op]
        "(#{_a} #{op} #{_b})"
      else
        module.bin_op_name_cb_map[ast.op](_a, _b)
    
    when "Un_op"
      module.un_op_name_cb_map[ast.op] gen ast.a, opt, ctx
    # 
    # when "Field_access"
    #   "(#{gen(ast.t, opt, ctx)}).#{ast.name}"
    # 
    when "Fn_call"
      ret = ""
      if ast.fn.constructor.name == 'Field_access'
        throw new Error "not implemented ast.fn.constructor.name == 'Field_access'"
        
      if !ret
        jl = []
        for v in ast.arg_list
          jl.push gen v, opt, ctx
        ret = "(#{gen ast.fn, opt, ctx})(#{jl.join ', '})"
      ret
    # when "Fn_call"
    #   ret = ""
    #   if ast.fn.constructor.name == 'Field_access'
    #     t = ast.fn.t
    #     ret = switch t.type.main
    #       when 'array'
    #         switch ast.fn.name
    #           when 'remove_idx', 'slice', 'pop', 'push', 'remove', 'idx', 'append', 'clone'
    #             ""# pass
    #           when 'new'
    #             "(#{gen t, opt, ctx}) = []"
    #           when 'length_set'
    #             "(#{gen t, opt, ctx}).length = #{gen ast.arg_list[0], opt, ctx}"
    #           when 'length_get'
    #             "(#{gen t, opt, ctx}).length"
    #           when 'sort_i', 'sort_f'
    #             "((#{gen t, opt, ctx}).sort)(#{gen ast.arg_list[0], opt, ctx})"
    #           when 'sort_by_i', 'sort_by_f'
    #             # !!! NON OPTIMAL !!!
    #             """
    #             _sort_by = #{gen ast.arg_list[0], opt, ctx}
    #             (#{gen t, opt, ctx}).sort (a,b)->_sort_by(a)-_sort_by(b)
    #             """
    #           when 'sort_by_s'
    #             # !!! NON OPTIMAL !!!
    #             """
    #             _sort_by = #{gen ast.arg_list[0], opt, ctx}
    #             (#{gen t, opt, ctx}).sort (a,b)->_sort_by(a).localeCompare _sort_by(b)
    #             """
    #           else
    #             throw new Error "unsupported #{t.type.main} method '#{ast.fn.name}'"
    #       when 'hash'
    #         switch ast.fn.name
    #           when 'new'
    #             "(#{gen t, opt, ctx}) = {}"
    #           else
    #             throw new Error "unsupported #{t.type.main} method '#{ast.fn.name}'"
    #       else
    #         if ast.fn.name == 'new'
    #           "(#{gen t, opt, ctx}) = new #{t.type.main}"
    #         else
    #           ""
    #   
    #   if !ret
    #     jl = []
    #     for v in ast.arg_list
    #       jl.push gen v, opt, ctx
    #     ret = "(#{gen ast.fn, opt, ctx})(#{jl.join ', '})"
    #   ret
    # ###################################################################################################
    #    stmt
    # ###################################################################################################
    when "Scope"
      jl = []
      for v in ast.list
        t = gen v, opt, ctx
        if t and t[t.length - 1] != ";"
          t += ";"
        jl.push t if t != ''
      jl.join "\n"
    
    when "If"
      cond = gen ast.cond, opt, ctx
      t = gen ast.t, opt, ctx
      f = gen ast.f, opt, ctx
      if f == ''
        """
        if (#{cond}) {
          #{make_tab t, '  '}
        }
        """
      else
        if ast.f.list[0]?.constructor.name == 'If'
          """
          if (#{cond}) {
            #{make_tab t, '  '}
          } else #{f}
          """
        else
          """
          if (#{cond}) {
            #{make_tab t, '  '}
          } else {
            #{make_tab f, '  '}
          }
          """
    # 
    # when "Switch"
    #   jl = []
    #   for k,v of ast.hash
    #     if ast.cond.type.main == 'string'
    #       k = JSON.stringify k
    #     jl.push """
    #     when #{k}
    #       #{make_tab gen(v, opt, ctx) or '0', '  '}
    #     """
    #   
    #   if "" != f = gen ast.f, opt, ctx
    #     jl.push """
    #     else
    #       #{make_tab f, '  '}
    #     """
    #   
    #   """
    #   switch #{gen ast.cond, opt, ctx}
    #     #{join_list jl, '  '}
    #   """
    # 
    # when "Loop"
    #   """
    #   loop
    #     #{make_tab gen(ast.scope, opt, ctx), '  '}
    #   """
    # 
    # when "While"
    #   """
    #   while #{gen ast.cond, opt, ctx}
    #     #{make_tab gen(ast.scope, opt, ctx), '  '}
    #   """
    # 
    # when "Break"
    #   "break"
    # 
    # when "Continue"
    #   "continue"
    # 
    # when "For_range"
    #   aux_step = ""
    #   if ast.step
    #     aux_step = " by #{gen ast.step, opt, ctx}"
    #   ranger = if ast.exclusive then "..." else ".."
    #   """
    #   for #{gen ast.i, opt, ctx} in [#{gen ast.a, opt, ctx} #{ranger} #{gen ast.b, opt, ctx}]#{aux_step}
    #     #{make_tab gen(ast.scope, opt, ctx), '  '}
    #   """
    # 
    # when "For_col"
    #   if ast.t.type.main == 'array'
    #     if ast.v
    #       aux_v = gen ast.v, opt, ctx
    #     else
    #       aux_v = "_skip"
    #     
    #     aux_k = ""
    #     if ast.k
    #       aux_k = ",#{gen ast.k, opt, ctx}"
    #     """
    #     for #{aux_v}#{aux_k} in #{gen ast.t, opt, ctx}
    #       #{make_tab gen(ast.scope, opt, ctx), '  '}
    #     """
    #   else
    #     if ast.k
    #       aux_k = gen ast.k, opt, ctx
    #     else
    #       aux_k = "_skip"
    #     
    #     aux_v = ""
    #     if ast.v
    #       aux_v = ",#{gen ast.v, opt, ctx}"
    #     """
    #     for #{aux_k}#{aux_v} of #{gen ast.t, opt, ctx}
    #       #{make_tab gen(ast.scope, opt, ctx), '  '}
    #     """
    # 
    # when "Ret"
    #   aux = ""
    #   if ast.t
    #     aux = " (#{gen ast.t, opt, ctx})"
    #   "return#{aux}"
    # 
    # when "Try"
    #   """
    #   try
    #     #{make_tab gen(ast.t, opt, ctx), '  '}
    #   catch #{ast.exception_var_name}
    #     #{make_tab gen(ast.c, opt, ctx), '  '}
    #   """
    # 
    # when "Throw"
    #   "throw new Error(#{gen ast.t, opt, ctx})"
    # 
    when "Var_decl"
      # TODO if ctx.in_class
      if ast.assign_value
        throw new Error "assign_value not implemented"
      if ast.size
        throw new Error "size not implemented"
      if ast.assign_value_list
        throw new Error "assign_value_list not implemented"
      "#{ast.type} #{ast.name}"
    # 
    # when "Class_decl"
    #   ctx_nest = ctx.mk_nest()
    #   ctx_nest.in_class = true
    #   # TODO seek constructor code
    #   constructor_jl = []
    #   for v in ast.scope.list
    #     switch v.constructor.name
    #       when "Var_decl"
    #         if module.need_constructor_reset[v.type.main]
    #           constructor_jl.push "@#{v.name} = #{module.default_value_from_type[v.type.main]}"
    #   aux_constructor = ""
    #   if constructor_jl.length
    #     aux_constructor = """
    #     
    #       constructor : ()->
    #         #{join_list constructor_jl, '    '}
    #     """
    #   
    #   """
    #   class #{ast.name}
    #     #{make_tab gen(ast.scope, opt, ctx_nest), '  '}#{aux_constructor}
    #   
    #   """
    # 
    # when "Fn_decl"
    #   arg_list = ast.arg_name_list
    #   ctx_nest = ctx.mk_nest()
    #   ctx_nest.in_class = false
    #   if ast.is_closure
    #     """
    #     (#{arg_list.join ', '})->
    #       #{make_tab gen(ast.scope, opt, ctx_nest), '  '}
    #     """
    #   else if ctx.in_class
    #     """
    #     #{ast.name} : (#{arg_list.join ', '})->
    #       #{make_tab gen(ast.scope, opt, ctx_nest), '  '}
    #     """
    #   else
    #     """
    #     #{ast.name} = (#{arg_list.join ', '})->
    #       #{make_tab gen(ast.scope, opt, ctx_nest), '  '}
    #     """
    else
      if opt.next_gen?
        return opt.next_gen ast, opt, ctx
      ### !pragma coverage-skip-block ###
      perr ast
      throw new Error "unknown ast.constructor.name=#{ast.constructor.name}"