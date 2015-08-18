Numeric Expressions
==================

*num_expr* → *term* *term_tail*

*term_tail* → *plus_op* *term* *term_tail* | *sub_op* *term* *term_tail* | *epsilon*

*term* → *factor* *factor_tail*

*factor_tail* → *mult_op* *factor* *factor_tail* | *div_op* *factor* *factor_tail* | *epsilon*

*factor* → *exp_operand* *exp_operand_tail*

*exp_operand_tail* → *exp_op* *exp_operand* *exp_operand_tail* | *epsilon*

*exp_operand* → ( *num_expr* ) | id | literal | *sub_op* *num_expr* | *plus_op* *num_expr*

*plus_op* → +

*sub_op* → -

*mult_op* → *

*div_op* → /

*exp_op* → ^

*epsilon* → 𝜖
