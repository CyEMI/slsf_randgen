classdef (SharedTestFixtures={ ...
        matlab.unittest.fixtures.PathFixture(['..' filesep '..']),...
        matlab.unittest.fixtures.PathFixture('.'),...   % To allow running test from the project directory by just adding this file's path
        matlab.unittest.fixtures.PathFixture(['3rdparty' filesep 'logging4matlab']),...
        matlab.unittest.fixtures.WorkingFolderFixture...
        }) DiffTesterTest < matlab.unittest.TestCase
    %DIFFTESTERTEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        systems = {'sampleModel2432', 'sampleModel2432_pp_1_1'}; % 'sampleModel2432_pp_1_1'
        
        configs = {
            {
                difftest.ExecConfig('Nrml', struct('SimulationMode', 'normal')) 
                difftest.ExecConfig('Acc', struct('SimulationMode', 'accelerator')) 
            }
            {
                difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
            }
        };
    end
    
    methods(TestClassSetup) % Only once for all methods
%         function open_systems(testCase)
%             for i=1:numel(testCase.systems)
%                 load_system(testCase.systems{i});
%                 fprintf('Loaded %s\n', testCase.systems{i});
%             end
%         end
    end
 
    methods(TestClassTeardown)
        function close_systems(testCase)
            for i=1:numel(testCase.systems)
                bdclose(testCase.systems{i});
            end
        end
    end
    
    methods(Test)
        %% Test Cases
        function testConfigBuilding(testCase)
            %%
            confs = {
                {
                    difftest.ExecConfig('Nrml', struct('SimulationMode', 'normal')) 
                    difftest.ExecConfig('Acc', struct('SimulationMode', 'accelerator')) 
                    difftest.ExecConfig('Rapid', struct('SimulationMode', 'rapid')) 
                }
                {
                    difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
            
            dt = difftest.BaseTester(testCase.systems, testCase.get_locs(testCase.systems), confs);
            dt.init_exec_reports();
            
            testCase.verifyEqual(dt.r.executions.len, 12, 'Cartesian product size incorrect');
            
            expected = load('cartesian');
            
            sysnames = cellfun(@(p)p.sys, dt.r.executions.get_cell_T(), 'UniformOutput', false);
            testCase.verifyEqual(sysnames, expected.sysnames, 'Model names incorrect');
            
            simargs = cellfun(@(p)p.get_sim_args(), dt.r.executions.get_cell());
            testCase.verifyEqual(simargs, expected.simargs, 'Simulation config values incorrect');
            
        end
        
        function testDiffTestOnlySingleModelOptOnOff(testCase)
            %%
            models = {'sampleModel2432'};
            confs = {
                {
                    difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
        
            testCase.exec(true, 'CachedDiffTestOnlySingleModelOptOnOff', models, confs, 2); 
        end
        
        function testTwoModelsOptimizationOnOff(testCase)
            %%
            models = {'sampleModel2432', 'sampleModel2432_pp_1_1'};
            confs = {
                {
                    difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
        
            testCase.exec(true, 'CachedTwoModelsOptimizationOnOff', models, confs, 4);
        end
        
        function testFinalValCompSingleModelOptOnOff(testCase)
            %%
            models = {'sampleModel2432'};
            confs = {
                {
                    difftest.ExecConfig('OptOn', struct('SimCompilerOptimization', 'on')) 
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
        
            r = testCase.exec(true, 'CachedFinalValCompSingleModelOptOnOff', models, confs, 2); 
            
            cf = testCase.comparison(@difftest.FinalValueComparator, {r}, true); 
            
            second_exec = cf.r.oks{2};
            testCase.assertEqual(second_exec.num_signals, second_exec.num_found_signals, ...
                'All signals of first and second simulation should be found');
        end
        
        function testFinalValCompErrTwoModels(testCase)
            %% The models have comp mismatch
            % the _pp_1_1 file is a wrong EMI-variant: created by simply
            % deleting a dead (Action Subsystem) block. As we saw, if done
            % in a live path this would create models not equivalent.
            models = {'sampleModel2432', 'sampleModel2432_pp_1_1'};
            confs = {
                {
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
        
            r = testCase.exec(true, 'CachedFinalValCompErrTwoModels', models, confs, 2);
            
            testCase.comparison(@difftest.FinalValueComparator, {r}, false); 
            
        end
        
        function testSameBlockCovAfterPP(testCase)
            %% Passing
            testCase.assumeFail();
            % This test is probably meeaningless since "Execution Coverage"
            % of a model can change after pre-processing. Imaginge live
            % blocks becoming dead (e.g. due to new data-type
            % converters some previous converter might now be dead, and
            % would report no coverage.
%             models = {'reduced_orig', 'reduced_pp'}; % reduced versions
            models = {'sampleModel2432', 'sampleModel2432_pp'}; 
            confs = {
                {
                    difftest.ExecConfig('OptOff', struct('SimCompilerOptimization', 'off')) 
                }
            };
        
            dt = difftest.BaseTester(models, testCase.get_locs(models),...
                confs,@difftest.deadcheck.SimpleExecutor,... % coverage col
                {@difftest.deadcheck.CoverageDecorator}); 

            r = testCase.run_cached_tester(false, 'CachedSameBlockCovAfterPP', dt);
            
            testCase.comparison(@difftest.deadcheck.CoverageComparator, {r}, false)
            
        end
    end
    
    methods
        %% Helper Methods
        
        function r = run_cached_tester(~, load_cache, cache_name, dt)
            
            function ret = inner()
                dt.go();
                ret = dt.r;
            end
            
            r = utility.load_cache_or_run(load_cache, cache_name,...
                utility.dirname(mfilename('fullpath')) , @inner);
        end
        
        function r = exec(testCase, load_cache, cache_name, models, confs, num_execution)
            dt = difftest.BaseTester(models, testCase.get_locs(models), confs);
            
            r = testCase.run_cached_tester(load_cache, cache_name, dt);
            
            testCase.assertEqual(r.executions.len, num_execution);
            testCase.assertTrue(r.is_ok);
        end
        
        function ret = get_locs(~, models)
            cellfun(@(p)emi.open_or_load_model(p), models);
            ret = cellfun(@(p)utility.strip_last_split(get_param(p, 'FileName'), filesep), models, 'UniformOutput', false);
        end
        
        function cf = comparison(testCase, comparator, args, expected)
            cf = comparator(args{:});
            cf.go();
            
            testCase.assertEqual(cf.r.are_oks_ok(), expected);
        end
    end
end

