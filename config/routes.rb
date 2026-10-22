RedmineApp::Application.routes.draw do
  get 'sla/dashboard', to: 'sla_dashboard#index', as: 'sla_dashboard'
  get 'admin/sla', to: 'sla_admin#index', as: 'sla_admin'
  post 'admin/sla/rebuild', to: 'sla_admin#rebuild', as: 'rebuild_sla_admin'

  get 'sla/deadlines/:id', to: 'sla_deadlines#show', as: 'sla_deadline'
  post 'sla/deadlines/:id/exclude', to: 'sla_deadlines#exclude', as: 'exclude_sla_deadline'
  delete 'sla/exclusions/:id', to: 'sla_exclusions#destroy', as: 'sla_exclusion'

  resources :sla_project_settings, except: [:index, :show]
  resources :sla_holidays, only: [:create, :destroy] do
    post :import, on: :collection
  end
  resources :sla_rules, except: [:show]

  get 'projects/:project_id/sla', to: 'sla_projects#show', as: 'project_sla'
end
