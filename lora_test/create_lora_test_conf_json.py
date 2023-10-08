import itertools
import inspect
import pandas as pd
import json
import openpyxl

def create_function_params_dictionary(func_name,convert_vals_to_lists = 1):
    argspec = inspect.getfullargspec(func_name)
    args = argspec.args

    # get the function argument values
    frame = inspect.currentframe()
    args_values = inspect.getargvalues(frame)
    print(f'args_values={args_values}')
    # Retrieve the values of the function's arguments
    values = [args_values.locals[arg] for arg in args_values.args]

    print(f'values={values}')

    dic = {}

    print(args)
    print(values)
    for i in range(len(args)):
        if (convert_vals_to_lists):
            if (isinstance(values[i], list)):
                value = values[i]
            else:
                value = [values[i]]
        else:
            value = values[i]
        dic[args[i]] = value

    return dic

def filter_function_arguments(args,values,args_filter,convert_vals_to_lists = 1):
    dic = {}

    for i in range(len(args)):
        if (args[i] in args_filter):
            if (convert_vals_to_lists):
                if (isinstance(values[i], list)):
                    value = values[i]
                else:
                    value = [values[i]]
            else:
                value = values[i]
            dic[args[i]] = value
    return dic






def get_permutations(config_dic):
# Get values for each key
    values = config_dic.values()
    pairs = []
# Generate pairs of values
    for combination in itertools.product(*values):
        pairs.append(list(combination))

# Display the pairs
    permute_dics = []
    for pair in pairs:
        permute_dics.append({k: v for k, v in zip(config_dic.keys(), pair)})

    return permute_dics


def create_missions_json(tx_frequency=2250):
    print(tx_frequency)

def create_lora_test_conf_json (
                                tx_frequency=2250,
                                duration = 255,
                                power = 1,
                                terminal_id = 121,
                                bandwidth = [125,250,500],
                                spreading_factor = [8,10,11],
                                efc_code = 0,
                                preamble_length = 9,
                                payload_length = 121,
                                delay_between_messages = 0,
                                Lwp = "",
                                sdr_port = "com3",
                                lora_rx_port = "com8",
                                lora_rx_port_baud_rate = 115200,
                                rcdat_http_ip = "192.168.200.76",
                                results_path = "./results",
                                json_file_name = "./lora_test_con.json",
                                L_max = 90,
                                L_base = 10,
                                L_coarse = 1,
                                L_fine = 0.25,
                                T_wp = 1, # (in minutes)
                                T_meas = 30, #(in minutes)
                                ):

    mission_parameters = [
                        'tx_frequency',
                        'duration',
                        'power',
                        'terminal_id',
                        'bandwidth',
                        'spreading_factor',
                        'efc_code',
                        'preamble_length',
                        'payload_length',
                        'delay_between_messages'
                        ]

    ports_parameters = [
                        'sdr_port',
                        'lora_rx_port',
                        'lora_rx_port_baud_rate'
                        ]

    algo_search_paramters = [
        "L_top",
        "L_max",
        "L_base",
        "L_coarse",
        "L_fine",
        "T_wp",
        "T_meas"
    ]

# get the function argument names
    argspec = inspect.getfullargspec(create_lora_test_conf_json)
    args = argspec.args

# get the function argument values
    frame = inspect.currentframe()

    args_values = inspect.getargvalues(frame)
    # Retrieve the values of the function's arguments
    values = [args_values.locals[arg] for arg in args_values.args]

# get missions dictionary
    mission_dic = filter_function_arguments(args,values,mission_parameters)
    missions_permute_dic = get_permutations(mission_dic)

    # get ports dictionary
    ports_dic = filter_function_arguments(args,values,ports_parameters,convert_vals_to_lists = 0)

    # get algo_search_paramters dictionary
    algo_search_dic = filter_function_arguments(args,values,algo_search_paramters,convert_vals_to_lists = 0)


    total_dic = {
                "ports":ports_dic,
                "rcdat_http_ip": rcdat_http_ip,
                "results_path":results_path,
                "search_algo_params":algo_search_dic,
                "missions":missions_permute_dic
                }

    total_dic = json.dumps(total_dic, indent=2)

    return total_dic

test_list_file = f'C:\workspace\lora_test\manager\kuku_temp.xlsx'
df = pd.read_excel(test_list_file)
print(df)




json_data = create_lora_test_conf_json(tx_frequency=915,spreading_factor=[8],bandwidth=250)
print(json_data)
with open('lora_test_conf_new.json', 'w') as file:
    file.write(json_data)


