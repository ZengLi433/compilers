(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)

class StackCommand {
};

class Node inherits IO {
    value : String;
    next  : Node;

    init(val : String, tail : Node) : Node { self };

    isNone() : Bool { false };

    getValue() : String { value };

    getNext() : Node { next };

    print(): Object { true };
};

class None inherits Node {
    isNone() : Bool { true };
};

class Stack inherits Node {
    init(val : String, tail : Node) : Node {
        {
            value <- val;
            next  <- tail;
            self;
        }
    };

    print() : Object {
        {
            out_string(value);
            out_string("\n");
            next.print();
        }
    };
};

class Main inherits IO {
    atoi  : A2I  <- new A2I;

    eval(s : Node) : Node {
        {
            if not s.isNone() then
                if s.getValue() = "+" then
                    let op1 : String, op2 : String, res : Int in {
                        s <- s.getNext();

                        op1 <- s.getValue();
                        s <- s.getNext();

                        op2 <- s.getValue();
                        s <- s.getNext();

                        res <- atoi.a2i(op1) + atoi.a2i(op2);
                        s <- (new Stack).init(atoi.i2a(res), s);

                        -- out_string("Adding ");
                        -- out_string(op1);
                        -- out_string(" and ");
                        -- out_string(op2);
                        -- out_string("\n");
                    }
                else
                    if s.getValue() = "s" then
                        let op1 : Node, op2 : Node in {
                            s <- s.getNext();

                            op1 <- s;
                            s <- s.getNext();

                            op2 <- s;
                            s <- s.getNext();

                            s <- (new Stack).init(op1.getValue(), s);
                            s <- (new Stack).init(op2.getValue(), s);

                            -- out_string("Swapped ");
                            -- out_string(op1.getValue());
                            -- out_string(" and ");
                            -- out_string(op2.getValue());
                            -- out_string("\n");
                        }
                    else
                        -- out_string("Nothing to do\n")
                        "continue"
                    fi
                fi
            else
                -- out_string("null stack\n")
                "continue"
            fi;
            s;
        }
    };

    main() : Object {
        {
            let i : String, stack : Node <- new None in
                while not (i = "x") loop {
                    out_string(">");

                    i <- in_string();

                    -- out_string(i);
                    out_string("\n");

                    if i = "+" then
                        stack <- (new Stack).init(i, stack)
                    else
                        if i = "s" then
                            stack <- (new Stack).init(i, stack)
                        else
                            if i = "e" then
                                stack <- eval(stack)
                            else
                                if i = "d" then
                                    stack.print()
                                else
                                    if not i = "x" then
                                        stack <- (new Stack).init(i, stack)
                                    else "continue" fi
                                fi
                            fi
                        fi
                    fi;
                }
                pool;
        }
    };

};
